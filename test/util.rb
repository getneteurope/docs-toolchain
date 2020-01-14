# frozen_string_literal: true

require 'asciidoctor'

# https://stackoverflow.com/a/22777806
def with_captured_stdout
  original_stdout = $stdout  # capture previous value of $stdout
  $stdout = StringIO.new     # assign a string buffer to $stdout
  yield                      # perform the body of the user code
  $stdout.string             # return the contents of the string buffer
ensure
  $stdout = original_stdout  # restore $stdout to its previous value
end

def assert_any_startwith(errors, text)
  assert_true(errors.any? { |err| err[:msg].start_with?(text) })
end

def init(content, name)
  document, _original = init2(content, name)
  return document
end

def init2(content, name, filename = nil)
  filename = name + '.adoc' if filename.nil?
  tempfile_path = write_tempfile(filename, content)
  document = Asciidoctor.load_file(tempfile_path, safe: :safe, catalog_assets: true)
  document.convert
  original = Asciidoctor.load_file(tempfile_path, safe: :safe, catalog_assets: true)
  return document, original
end
