require_relative "./cli.rb"
require_relative "./extension_manager.rb"
require_relative "../../../utils/ruby_utils.rb"
Dir[File.join(__dir__, "modules.d", "*.rb")].each { |file| require file }

ADOC_MAP = Hash.new(nil)

def load_doc(filename)
  adoc = Asciidoctor.load_file(filename, catalog_assets: true)
  adoc.convert
  return adoc
end

def run_tests(filename)
  if ADOC_MAP[filename].nil?
    adoc = load_doc(filename)
    ADOC_MAP[filename] = adoc
  else
    adoc = ADOC_MAP[filename]
  end

  errors = []
  Toolchain::ExtensionManager.instance.get.each do |ext|
    errors += ext.run(adoc)
  end
  return errors
end

def check_docs(included_files=nil)
  errors_map = {}
  adoc_files = included_files unless included_files.nil?
  adoc_files = Dir.glob("**/*.adoc") if included_files.nil?
  adoc_files.each do |f|
    errors = run_tests(f)
    errors_map[f] = errors
  end
  return errors_map
end

def main(argv=ARGV)
  args = parse_args(argv)
  ### Print help
  if args.help
    puts "Usage: ./script [--help] [--debug] [--index INDEX] [--file FILE] ..."
    puts
    puts "Provide either:"
    puts "        INDEX    a single index file, automatically following the include statements to find errors"
    puts "        FILE     one or multiple files, includes will not be followed"
    puts "        NOTHING  same as INDEX with INDEX='index.adoc'"
    return 0
  end

  ### Print loaded modules
  if args.debug
    puts "*** Loaded extensions:"
    Toolchain::ExtensionManager.instance.get.each do |ext|
      puts ext.class.name
    end
  end

  ### Run on file arguments
  if args.file
    args.files.each do |f|
      errors = run_tests(f)
      if errors
        puts f.blue.bold
        errors.each do |err|
          puts "#{err[:id]}\t#{err[:msg]}".bold.red
        end
      end
    end
    return 0
  end

  ### Run checks on default files
  index_adoc = (args.index || "index.adoc")
  included_files = load_doc(index_adoc).catalog[:includes]
  ### CHECK INDEX FIRST
  index_errors = run_tests(index_adoc)
  if index_errors.empty?
    puts "No errors found in index.adoc!".bold.green
    return 0
  end

  errors_map = check_docs(included_files)
  puts errors_map
  # TODO: process errors_map to show which error in index is in which source file
end
