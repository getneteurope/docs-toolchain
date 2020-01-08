# frozen_string_literal: true

require_relative './extension_manager.rb'

module Toolchain
  class BaseExtension
    def next_id
      return Toolchain::ExtensionManager.instance.next_id
    end

    def create_error(id: nextId, type: self.class.name, msg:, filename:, lineno: nil, extras: nil)
      where = filename
      lineno&.each { |line| where << ":#{line}" }
      return {
        id: id,
        type: type,
        msg: msg,
        where: where,
        extras: extras
      }
    end

    def run(_document)
      # run takes a document (a converted asciidoctor document) as input and
      # must return an array of Hashes of errors.
      # if there are no errors, an empty Hash must be returned.
      # the Hash has the following format:
      # {
      # id: from nextId
      # type: string
      # where: string or list of strings (filenames + line numbers,
      #                                   e.g. "test.adoc:12:15:17"
      #                                   for line 12, 15 and 17)
      # extras: hash, containing key value pairs for future use
      # }
      raise NotImplementedError.new, "#{self.class.name}: no implementation for 'run'"
    end
  end
end
