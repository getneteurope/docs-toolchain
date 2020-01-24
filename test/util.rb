# frozen_string_literal: true

require 'asciidoctor'

def write_tempfile(name, content, prefix: 'test_toolchain_', suffix: nil)
  tempfile_path = File.join('/tmp', "#{prefix}#{name}#{suffix}")
  tmp = File.open(tempfile_path, 'w+')
  begin
    tmp.write(content)
  ensure
    tmp.close
  end
  log('TMP_FILE', tempfile_path, :gray)
  return tempfile_path
end

def with_tempfile(content)
  file = write_tempfile('tmpfile', content, prefix: 'unittest_') # write tempfile with content
  yield(file) # call block with file as argument
end

def with_captured_stdout
  return with_captured(stderr: false) { yield }
end

def with_captured_stderr
  return with_captured(stdout: false) { yield }
end

##
# https://stackoverflow.com/a/22777806
def with_captured(stdout: true, stderr: true)
  original = [$stdout, $stderr]
  tmp = StringIO.new
  $stdout = tmp if stdout
  $stderr = tmp if stderr
  yield
  return tmp.string
ensure
  $stdout, $stderr = original
end

def assert_any_startwith(errors, text)
  assert_true(errors.any? { |err| err[:msg].start_with?(text) })
end

def init(content, name, filename = nil)
  filename = name + '.adoc' if filename.nil?
  tempfile_path = write_tempfile(filename, content)
  adoc = load_doc(tempfile_path)
  return adoc
end
