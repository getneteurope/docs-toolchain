# frozen_string_literal: true

#
# Extends the Html5Converter to generate multiple pages from the document tree.
#
# Features:
#
# - Generates a root (top level) landing page with a list of child sections.
# - Generates branch (intermediate level) landing pages as required, each with
#   a list of child sections.
# - Generates leaf (content level) pages with the actual content.
# - Allows the chunking depth to be configured with the `multipage-level`
#   document attribute (the default is 1—split into chapters).
# - Supports variable chunking depth between sections in the document (by
#   setting the `multipage-level` attribute on individual sections).
# - Uses section IDs to name each page (eg. "introduction.html").
# - Supports cross-references between pages.
# - Generates a full Table of Contents for each page, but with relevant entries
#   only (the TOC collapses as required for each page).
# - Includes a description for each section on the branch/leaf landing pages
#   (from the `desc` attribute, if set).
# - Generates previous/up/home/next navigation links for each page.
# - Allows the TOC entry for the current page to be styled with CSS.
# - Supports standalone and embedded (--no-header-footer) HTML output.
# - Retains correct section numbering throughout.
#
# Notes and limitations:
#
# - Tested with Asciidoctor 2.0.0; inline anchors in unordered list items
#   require the fix for asciidoctor issue #2812.
# - This extension is tightly coupled with Asciidoctor internals, and future
#   changes in Asciidoctor may require updates here. Hopefully this extension
#   exposes ways in which the Asciidoctor API can be improved.
# - Footnotes are currently not supported.
# - Please contribute fixes and enhancements!
#
# Usage:
#
#   asciidoctor -r ./multipage-html5-converter.rb -b multipage_html5 book.adoc

require 'asciidoctor/converter/html5'
require 'nokogiri'
require_relative '../utils/create_toc.rb'

# HTML5 Multipage Converter adapted Asciidoctor::AbstractBlock
class Asciidoctor::AbstractBlock
  # Allow navigation links HTML to be saved and retrieved
  attr_accessor :nav_links

  # HACK this forces the renumbering of sections and therefore
  # the correction of @next_section_index, which would be
  # inaccurate otherwise and this leads to Nil errors in
  # Asciidoctor core.
  def sections?
    reindex_sections
    @next_section_index > 0
  end
end

# HTML5 Multipage Converter adapted Asciidoctor::AbstractNode
class Asciidoctor::AbstractNode
  # Is this node (self) of interest when generating a TOC for node?
  #
  # Returns true if node is of interest, false otherwise.
  #
  def related_to?(node)
    return true if level.zero?

    node_tree = []
    current = node
    while current.class != Asciidoctor::Document
      node_tree << current
      current = current.parent
    end
    if node_tree.include?(self) ||
        node_tree.include?(parent)
      return true
    end

    # If this is a leaf page, include all child sections in TOC
    if node.mplevel == :leaf
      self_tree = []
      current = self
      while current && current.level >= node.level
        self_tree << current
        current = current.parent
      end
      return true if self_tree.include?(node)
    end
    return false
  end
end

# HTML5 Multipage Converter adapted Asciidoctor::Document
class Asciidoctor::Document
  # Allow writing to the :catalog attribute in order to duplicate refs list to
  # new pages
  attr_writer :catalog

  # Allow the section type to be saved (for when a Section becomes a Document)
  attr_accessor :mplevel

  # Allow the current Document to be marked as processed by this extension
  attr_accessor :processed

  # Allow saving of section number for use later. This is necessary for when a
  # branch or leaf Section becomes a Document during chunking and ancestor
  # nodes are no longer accessible.
  attr_writer :sectnum

  # Override the AbstractBlock sections?() check to enable the Table Of
  # Contents. This extension may generate short pages that would normally have
  # no need for a TOC. However, we override the Html5Converter outline() in
  # order to generate a custom TOC for each page with entries that span the
  # entire document.
  #
  def sections?
    return !sections.empty?
  end

  # Return the saved section number for this Document object (which was
  # originally a Section)
  #
  def sectnum(delimiter = nil, append = nil)
    @sectnum
  end
end

# HTML5 Multipage Converter adapted Asciidoctor::Document
class Asciidoctor::Section
  # Allow the section type (:root, :branch, :leaf) to be saved for each section
  attr_accessor :mplevel

  # Extend sectnum() to use the Document's saved sectnum. Document objects
  # normally do not have sectnums, but here Documents are generated from
  # Sections. The sectnum is saved in section() below.
  #
  # Returns the formatted sectnum.
  #
  def sectnum(delimiter = '.', append = nil)
    append ||= (append == false ? '' : delimiter)
    if @level == 1
      %(#{@numeral}#{append})
    elsif @level > 1
      if @parent.class == Asciidoctor::Section ||
          (@mplevel && @parent.class == Asciidoctor::Document)
        %(#{@parent.sectnum(delimiter)}#{@numeral}#{append})
      else
        %(#{@numeral}#{append})
      end
    else # @level == 0
      %(#{Asciidoctor::Helpers.int_to_roman @numeral}#{append})
    end
  end
end

# HTML5 Multipage Converter based on HTML5 Converter
class MultipageHtml5Converter < Asciidoctor::Converter::Html5Converter
  include Asciidoctor
  include Asciidoctor::Converter
  include Asciidoctor::Writer

  register_for 'multipage_html5'

  def initialize(backend, opts = {})
    @xml_mode = false
    @void_element_slash = nil
    super
    @stylesheets = Stylesheets.instance
    @pages = []
  end

  # Add navigation links to the page (from nav_links)
  #
  # Returns nothing.
  #
  def add_nav_links(page)
    block = Asciidoctor::Block.new(parent = page,
      :paragraph,
      opts = { source: page.nav_links })
    block.add_role('nav-footer')
    page << block
  end

  # Extend Asciidoctor's convert().
  #
  # Returns transformed node.
  #
  def convert(node, transform = nil, opts = {})
    transform ||= node.node_name
    begin
      opts.empty? ? (send transform, node) : (send transform, node, opts)
    rescue StandardError => e
      # HACK dirty hack for exception that gets raised when trying 'open',
      # which should be 'convert_open' in the first place.
      begin
        transform = "convert_#{node.node_name}"
        opts.empty? ? (send transform, node) : (send transform, node, opts)
      rescue StandardError => e
        error("#{e.class}: #{e.message}")
        error("#{node}.#{transform}".bold.red)
        error('No conversion for node:'.bold.red)
        error(node)
        error('Exiting.'.bold.red)
        raise e
      end
    end
  end

  # Process Document (either the original full document or a processed page)
  #
  # Returns converted node.
  #
  def document(node)
    if node.processed
      # This node can now be handled by Html5Converter.
      super
    else
      # This node is the original full document which has not yet been
      # processed; this is the entry point for the extension.

      # Turn off extensions to avoid running them twice.
      # FIXME: DocinfoProcessor, InlineMacroProcessor, and Postprocessor
      # extensions should be retained. Is this possible with the API?
      # Asciidoctor::Extensions.unregister_all

      # Check toclevels and multipage-level attributes
      mplevel = node.document.attr('multipage-level', 1).to_i
      toclevels = node.document.attr('toclevels', 2).to_i
      if toclevels < mplevel
        logger.warn 'toclevels attribute should be >= multipage-level'
      end
      if mplevel < 0
        logger.warn 'multipage-level attribute must be >= 0'
        mplevel = 0
      end
      node.document.set_attribute('multipage-level', mplevel.to_s)

      # Set multipage chunk types
      set_multipage_attrs(node)

      # Set the "id" attribute for the Document, using the "docname", which is
      # based on the file name. Then register the document ID using the
      # document title. This allows cross-references to refer to (1) the
      # top-level document itself or (2) anchors in top-level content (blocks
      # that are specified before any sections).
      node.id = node.attributes['docname']
      node.register(:refs, [node.id,
        Inline.new(parent = node,
          context = :anchor,
          text = node.doctitle,
          opts = { type: :ref,
            id: node.id }),
        node.doctitle])

      # Generate navigation links for all pages
      generate_nav_links(node)

      # Create and save a skeleton document for generating the TOC lists.
      @@full_outline = new_outline_doc(node)

      # Save the document catalog to use for each part/chapter page.
      @catalog = node.catalog

      # Retain any book intro blocks, delete others, and add a list of sections
      # for the book landing page.
      parts_list = Asciidoctor::List.new(node, :ulist)
      node.blocks.delete_if do |block|
        if block.context == :section
          part = block
          part.convert
          text = %(<<#{part.id},#{part.captioned_title}>>)
          # if desc = block.attr('desc') then text << %( – #{desc}) end
          parts_list << Asciidoctor::ListItem.new(parts_list, text)
        end
      end
      node << parts_list

      # Add navigation links
      add_nav_links(node)

      # Mark page as processed and return converted result
      node.processed = true
      node.convert
    end
  end

  # Process Document in embeddable mode (either the original full document or a
  # processed page)
  def embedded(node)
    if node.processed
      # This node can now be handled by Html5Converter.
      super
    else
      # This node is the original full document which has not yet been
      # processed; it can be handled by document().
      document(node)
    end
  end

  # Generate navigation links for all pages in document; save HTML to nav_links
  def generate_nav_links(doc)
    pages = doc.find_by(context: :section) do |section|
      %i[root branch leaf].include?(section.mplevel)
    end

    pages.insert(0, doc)
    pages.each do |page|
      page_index = pages.find_index(page)
      links = []
      if page.mplevel != :root
        previous_page = pages[page_index - 1]
        parent_page = page.parent
        home_page = doc
        # NOTE, there are some non-breaking spaces (U+00A0) below.
        links << %(← <<#{previous_page.id}>>) if previous_page != parent_page
        # links << %(↑ <<#{parent_page.id}>>)
        # links << %(⌂ <<#{home_page.id}>>) if home_page != parent_page
      end
      if page_index != pages.length - 1
        next_page = pages[page_index + 1]
        links << %( <<#{next_page.id}>> →)
      end
      block = Asciidoctor::Block.new(parent = doc,
        context = :paragraph,
        opts = { source: links.join(' | '), subs: :default })
      page.nav_links = block.content
    end
    return
  end

  # Generate the actual HTML outline for the TOC. This method is analogous to
  # Html5Converter outline().
  def generate_outline(node, opts = {})
    # This is the same as Html5Converter outline()
    return unless node.sections?
    return if node.sections.empty?

    sectnumlevels = opts[:sectnumlevels] || (node.document.attr 'sectnumlevels', 3).to_i
    toclevels = opts[:toclevels] || (node.document.attr 'toclevels', 2).to_i
    sections = node.sections
    result = [%(<ul class="sectlevel#{sections[0].level}">)]
    sections.each do |section|
      slevel = section.level
      stitle = if section.caption
                 section.captioned_title
               elsif section.numbered && slevel <= sectnumlevels
                 %(#{section.sectnum} #{section.title})
               else
                 section.title
               end
      stitle = stitle.gsub DropAnchorRx, '' if stitle.include? '<a'

      # But add a special style for current page in TOC
      if section.id == opts[:page_id]
        stitle = %(<span class="toc-current">#{stitle}</span>)
      end

      # And we also need to find the parent page of the target node
      current = section
      current = current.parent until current.mplevel != :content
      parent_chapter = current

      # If the target is the top-level section of the parent page, there is no
      # need to include the anchor.
      link = if parent_chapter.id == section.id
               %(#{parent_chapter.id}.html)
             else
               %(#{parent_chapter.id}.html##{section.id})
             end
      result << %(<li><a href="#{link}">#{stitle}</a>)

      # Finish in a manner similar to Html5Converter outline()
      if slevel < toclevels &&
          (child_toc_level = generate_outline section,
            toclevels: toclevels,
            secnumlevels: sectnumlevels,
            page_id: opts[:page_id])
        result << child_toc_level
      end
      result << '</li>'
    end
    result << '</ul>'
    result.join LF
  end

  # Include chapter pages in cross-reference links. This method overrides for
  # the :xref node type only.
  def inline_anchor(node)
    if node.type == :xref
      # This is the same as super...
      if (path = node.attributes['path'])
        attrs = (append_link_constraint_attrs node, node.role ? [%( class="#{node.role}")] : []).join
        text = node.text || path
      else
        attrs = node.role ? %( class="#{node.role}") : ''
        unless (text = node.text)
          refid = node.attributes['refid']
          if AbstractNode === (ref = (@refs ||= node.document.catalog[:refs])[refid])
            text = (ref.xreftext node.attr('xrefstyle')) || %([#{refid}])
          else
            text = %([#{refid}])
          end
        end
      end

      # But we also need to find the parent page of the target node.
      current = node.document.catalog[:refs][node.attributes['refid']]
      until current.respond_to?(:mplevel) && current.mplevel != :content
        return %(<a href="#{node.target}"#{attrs}>#{text}</a>) unless current

        current = current.parent
      end
      parent_page = current

      # If the target is the top-level section of the parent page, there is no
      # need to include the anchor.
      target = if node.target == "##{parent_page.id}"
                 "#{parent_page.id}.html"
               else
                 "#{parent_page.id}.html#{node.target}"
               end

      %(<a href="#{target}"#{attrs}>#{text}</a>)
    else
      # Other anchor types can be handled as normal.
      super
    end
  end

  # From node, create a skeleton document that will be used to generate the
  # TOC. This is first used to create a full skeleton (@@full_outline) from the
  # original document (for_page=nil). Then it is used for each individual page
  # to create a second skeleton from the first. In this way, TOC entries are
  # included that are not part of the current page, or excluded if not
  # applicable for the current page.
  def new_outline_doc(node, new_parent: nil, for_page: nil)
    if node.class == Document
      new_document = Document.new([])
      new_document.mplevel = node.mplevel
      new_document.id = node.id
      new_document.set_attr('sectnumlevels', node.attr(:sectnumlevels))
      new_document.set_attr('toclevels', node.attr(:toclevels))
      new_parent = new_document
      node.sections.each do |section|
        new_outline_doc(section, new_parent: new_parent,
          for_page: for_page)
      end
      # Include the node if either (1) we are creating the full skeleton from the
      # original document or (2) the node is applicable to the current page.
    elsif !for_page ||
        node.related_to?(for_page)
      new_section = Section.new(parent = new_parent,
        level = node.level,
        numbered = node.numbered)
      new_section.id = node.id
      new_section.caption = node.caption
      new_section.title = node.title
      new_section.mplevel = node.mplevel
      new_parent << new_section
      new_parent.sections.last.numeral = node.numeral
      new_parent = new_section

      node.sections.each do |section|
        new_outline_doc(section, new_parent: new_parent,
          for_page: for_page)
      end
    end
    return new_document
  end

  # Override Html5Converter outline() to return a custom TOC outline
  def outline(node, opts = {})
    doc = node.document
    # Find this node in the @@full_outline skeleton document
    page_node = @@full_outline.find_by(id: node.id).first
    # Create a skeleton document for this particular page
    custom_outline_doc = new_outline_doc(@@full_outline, for_page: page_node)
    opts[:page_id] = node.id
    # Generate an extra TOC entry for the root page. Add additional styling if
    # the current page is the root page.
    root_file = %(#{doc.attr('docname')}#{doc.attr('outfilesuffix')})
    root_link = %(<a href="#{root_file}">#{doc.doctitle}</a>)
    classes = ['toc-root']
    classes << 'toc-current' if node.id == doc.attr('docname')
    root = %(<span class="#{classes.join(' ')}">#{root_link}</span>)
    # Create and return the HTML
    %(<p>#{root}</p>#{generate_outline(custom_outline_doc, opts)})
  end

  # Change node parent to new parent recursively
  def reparent(node, parent)
    node.parent = parent
    if node.context == :dlist
      node.find_by(context: :list_item).each do |block|
        reparent(block, node)
      end
    else
      node.blocks.each do |block|
        reparent(block, node)
        next unless block.context == :table

        block.columns.each do |col|
          col.parent = col.parent
        end
        block.rows.body.each do |row|
          row.each do |cell|
            cell.parent = cell.parent
          end
        end
      end
    end
  end

  # Process a Section. Each Section will either be split off into its own page
  # or processed as normal by Html5Converter.
  def section(node)
    doc = node.document
    if doc.processed
      # This node can now be handled by Html5Converter.
      super
    else
      # This node is from the original document and has not yet been processed.

      # Create a new page for this section
      page = ::Asciidoctor::Document.new([],
        attributes: doc.attributes.clone,
        doctype: doc.doctype,
        header_footer: !doc.attr?(:embedded),
        safe: doc.safe)
      # Retain webfonts attribute (why is doc.attributes.clone not adequate?)
      page.set_attr('webfonts', doc.attr(:webfonts))
      # Save sectnum for use later (a Document object normally has no sectnum)
      if node.parent.respond_to?(:numbered) && node.parent.numbered
        page.sectnum = node.parent.sectnum
      end

      # Process node according to mplevel
      if node.mplevel == :branch
        # Retain any part intro blocks, delete others, and add a list
        # of sections for the part landing page.
        chapters_list = Asciidoctor::List.new(node, :ulist)
        node.blocks.delete_if do |block|
          if block.context == :section
            chapter = block
            chapter.convert
            text = %(<<#{chapter.id},#{chapter.captioned_title}>>)
            # NOTE, there is a non-breaking space (Unicode U+00A0) below.
            if desc = block.attr('desc') then text << %( – #{desc}) end
            chapters_list << Asciidoctor::ListItem.new(chapters_list, text)
            true
          end
        end
        # Add chapters list to node, reparent node to new page, add
        # node to page, mark as processed, and add page to @pages.
        node << chapters_list
        reparent(node, page)
        page.blocks << node
      else # :leaf
        # Reparent node to new page, add node to page, mark as
        # processed, and add page to @pages.
        reparent(node, page)
        page.blocks << node
      end

      # Add navigation links using saved HTML
      page.nav_links = node.nav_links
      add_nav_links(page)

      # Mark page as processed and add to collection of pages
      @pages << page
      page.id = node.id
      page.catalog = @catalog
      page.mplevel = node.mplevel
      page.processed = true
    end
  end

  # Add multipage attribute to all sections in node, recursively.
  def set_multipage_attrs(node)
    doc = node.document
    node.mplevel = :root if node.class == Asciidoctor::Document
    node.sections.each do |section|
      if !section.attr?('multipage-level')
        section.set_attr('multipage-level', node.attr('multipage-level'))
      end
      # Propogate custom multipage-level value to child node
      if !section.attr?('multipage-level', nil, false) &&
          node.attr('multipage-level') != doc.attr('multipage-level')
        section.set_attr('multipage-level', node.attr('multipage-level'))
      end
      # Set section type
      if section.level < section.attr('multipage-level').to_i
        section.mplevel = :branch
      elsif section.level == section.attr('multipage-level').to_i
        section.mplevel = :leaf
      else
        section.mplevel = :content
      end
      # Set multipage attribute on child sections now.
      set_multipage_attrs(section)
    end
  end

  # Convert each page and write it to file. Use filenames based on IDs.
  def write(output, target)
    # Write primary (book) landing page
    ::File.open(target, 'w') do |f|
      f.write(output)
    end
    # Write remaining part/chapter pages
    outdir = ::File.dirname(target)
    ext = ::File.extname(target)
    target_name = ::File.basename(target, ext)
    @pages.each do |doc|
      chapter_target = doc.id + ext
      outfile = ::File.join(outdir, chapter_target)
      ::File.open(outfile, 'w') do |f|
        f.write(doc.convert)
      end
    end
  end
end

# Table Of Content Injector
#
# Inject the beforehand created Table Of Content into every page,
# including the logo under `images/logo.png` and the search input field.
#
class TableOfContentInjector < Asciidoctor::Extensions::Postprocessor
  def process(document, output)
    toc_factory = ::Toolchain::Adoc::CreateTOC.new
    _, toc_html_filepath, _ = toc_factory.run(document.catalog)
    toc = File.read(toc_html_filepath)
    html = Nokogiri::HTML(output)

    # filename is based on ID, see `write` method above
    filename = document.id + '.html'
    toc_document = Nokogiri::HTML.fragment(toc)
    toc_document = toc_factory.tick_toc_checkboxes(document.id, toc_document)
    # table of content
    html.at_css('div#toc').remove if html.at_css('div#toc')
    html.at_css('body').children.first.add_previous_sibling(toc_document)
    # logo
    html.at_css('div#toc').children.first.add_previous_sibling(
      '<a id="logo" href="index.html"><img src="images/logo.png" alt="Logo"></a>'
    )
    # search and search overlay
    search_overlay = File.read(
      File.join(::Toolchain.build_path, 'docinfo-search.html'))
    html.at_css('div#toc').children.first.add_next_sibling(search_overlay)

    return html.to_html
  end
end

# CodeRay CSS Injector
#
# By default, Asciidoctor will put the CodeRay CSS file in the body
# of the HTML as one of the very last tags.
# In addition, this will only be injected if the page has actual source code on it.
# Given, that we use the page switch functionality to only change the `div#content`
# when clicking on a new subsection, this tag needs to be on every page.
# Only then will every source code block show correctly, even if switching from a page
# without source code.
#
# This class will add the coderay-asciidoctor.css to every document head and
# remove the CSS link tag in the body, if it exists.
#
class CodeRayCSSInjector < Asciidoctor::Extensions::Postprocessor
  # Always add the link tag in the head after the others.
  # Check for the link tag loading coderay-asciidoctor.css and
  # remove it from the body.
  def process(document, output)
    html = Nokogiri::HTML(output)
    coderay_css = 'css/coderay-asciidoctor.css'

    # get the coderay CSS if it exists and remove it
    coderay_css_tag = html.at_xpath('html/body/link')
    coderay_css_tag.remove if coderay_css_tag

    css_links = html.xpath('html/head/link')
    last_css_link = css_links.last
    # only add the link if it's not already present (index file gets processed twice)
    if (!last_css_link.nil?) && last_css_link.attr('href') != coderay_css
      css_links.last.add_next_sibling(
        '<link rel="stylesheet" href="css/coderay-asciidoctor.css">'
      )
    end

    return html.to_html
  end
end

Asciidoctor::Extensions.register do
  if %w[html html5 multipage_html5].any? { |be| @document.basebackend?(be) }
    postprocessor TableOfContentInjector
    postprocessor CodeRayCSSInjector
  end
end
