# typed: strict
# frozen_string_literal: true

module Utils
  module Bottles
    class << self
      module MacOSOverride
        sig { params(tag: T.nilable(T.any(Symbol, Tag))).returns(Tag) }
        def tag(tag = nil)
          return Tag.new(system: MacOS.version.to_sym, arch: Hardware::CPU.arch) if tag.nil?

          super
        end
      end

      prepend MacOSOverride
    end

    class Collector
      private

      alias generic_find_matching_tag find_matching_tag

      sig { params(tag: Utils::Bottles::Tag, no_older_versions: T::Boolean).returns(T.nilable(Utils::Bottles::Tag)) }
      def find_matching_tag(tag, no_older_versions: false)
        # Used primarily by developers testing beta macOS releases.
        if no_older_versions ||
           (OS::Mac.version.prerelease? &&
            Homebrew::EnvConfig.developer? &&
            Homebrew::EnvConfig.skip_or_later_bottles?)
          generic_find_matching_tag(tag)
        else
          generic_find_matching_tag(tag) ||
            find_older_compatible_tag(tag)
        end
      end

      # Find a bottle built for a previous version of macOS.
      sig { params(tag: Utils::Bottles::Tag).returns(T.nilable(Utils::Bottles::Tag)) }
      def find_older_compatible_tag(tag)
        tag_version = begin
          tag.to_macos_version
        rescue MacOSVersion::Error
          nil
        end

        return if tag_version.blank?

        tags.find do |candidate|
          next if candidate.standardized_arch != tag.standardized_arch

          candidate.to_macos_version <= tag_version
        rescue MacOSVersion::Error
          false
        end
      end
    end
  end
end
