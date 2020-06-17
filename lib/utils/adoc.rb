# frozen_string_literal: true

require 'ostruct'
require 'asciidoctor'
require_relative '../utils/paths.rb'

module Toolchain
  # Module containing Asciidoctor related Toolchain manipulations.
  module Adoc
    ##
    # Load adoc file +filename+, convert given the parameters +safe+ and +parse+
    # https://discuss.asciidoctor.org/Compiling-all-includes-into-a-master-Adoc-file-td2308.html
    #
    # Returns an OpenStruct of converted adoc +adoc+, original adoc +original+,
    # attributes +attributes+ and filename +filename+.
    #
    def self.load_doc(filename, attribs = {'root' => Toolchain.build_path})
      root = attribs['root']
      ci_logger = ::Toolchain::Logger
      if filename.start_with?('/')
        root = File.dirname(filename)
        attribs['root'] = root
        filename = File.basename(filename)
      end
      original = ::Asciidoctor.load_file(
        File.join(root, filename),
        catalog_assets: true,
        sourcemap: true,
        safe: :unsafe,
        parse: false,
        attributes: attribs#,
        #logger: ::Logger.new('/dev/null')
      )
      parsed = ::Asciidoctor.load_file(
        File.join(root, filename),
        catalog_assets: true,
        sourcemap: true,
        safe: :unsafe,
        parse: true,
        attributes: attribs
      )
      attributes = collect_attributes(parsed, attribs)

      adoc = ::OpenStruct.new(
        original: original,
        parsed: parsed,
        attributes: attributes,
        filename: filename
      )
      return adoc
    end

    ##
    # Recursively loops thourgh asdciidoc includes and collects their newly set attributes.
    # Adds +additional_attribs+ to the attribute hash if they are passed.
    # Returns collection of attributes +attribs+.
    #
    def self.collect_attributes(doc, additional_attribs = {})
      # get initial attribs set in index
      attribs = get_mod_attrs_from_doc(doc)
      additional_attribs.each do |key,value|
        attribs[key] = value
      end
      incs = doc.catalog[:includes].keys.to_set
      return attribs if incs.empty?

      document_base_dir = doc.base_dir
      incs.each do |inc|
        inc_file_path = doc.normalize_asset_path(inc + '.adoc')
        doc = ::Asciidoctor.load_file(
          inc_file_path,
          base_dir: document_base_dir,
          catalog_assets: true,
          sourcemap: true,
          safe: :unsafe,
          parse: false,
          attributes: attribs
        )
        # combine new modified attr from current file with existing attribs
        get_mod_attrs_from_doc(doc).each do |k, v|
          attribs[k] = v
        end
        collect_attributes(doc, attribs)
      end
      attribs
    end

    ##
    # Takes document +doc+.
    #
    # Returns +attribs+ all attributes newly set in this document.
    #
    def self.get_mod_attrs_from_doc(doc)
      attribs = {}
      doc.convert
      attrs_mod = doc.instance_variable_get :@attributes_modified
      attrs_mod.each do |k, _v|
        attribs[k] = doc.attributes[k]
      end
      attribs
    end

  end
end
