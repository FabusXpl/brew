# typed: true # rubocop:disable Sorbet/StrictSigil
# frozen_string_literal: true

module OS
  module Mac
    module Superenv
      extend T::Helpers

      requires_ancestor { SharedEnvExtension }
      requires_ancestor { ::Superenv }

      module ClassMethods
        sig { returns(Pathname) }
        def shims_path
          HOMEBREW_SHIMS_PATH/"mac/super"
        end

        sig { returns(T.nilable(Pathname)) }
        def bin
          return unless ::DevelopmentTools.installed?

          shims_path.realpath
        end
      end

      sig { returns(T::Array[Pathname]) }
      def homebrew_extra_pkg_config_paths
        [Pathname("/usr/lib/pkgconfig"), Pathname("#{HOMEBREW_LIBRARY}/Homebrew/os/mac/pkgconfig/#{MacOS.version}")]
      end

      sig { returns(T::Boolean) }
      def libxml2_include_needed?
        return false if deps.any? { |d| d.name == "libxml2" }
        return false if Pathname("#{self["HOMEBREW_SDKROOT"]}/usr/include/libxml").directory?

        true
      end

      def homebrew_extra_isystem_paths
        paths = []
        paths << "#{self["HOMEBREW_SDKROOT"]}/usr/include/libxml2" if libxml2_include_needed?
        paths << "#{self["HOMEBREW_SDKROOT"]}/usr/include/apache2" if MacOS::Xcode.without_clt?
        paths << "#{self["HOMEBREW_SDKROOT"]}/System/Library/Frameworks/OpenGL.framework/Versions/Current/Headers"
        paths
      end

      def homebrew_extra_library_paths
        paths = []
        if compiler == :llvm_clang
          paths << "#{self["HOMEBREW_SDKROOT"]}/usr/lib"
          paths << ::Formula["llvm"].opt_lib.to_s
        end
        paths << "#{self["HOMEBREW_SDKROOT"]}/System/Library/Frameworks/OpenGL.framework/Versions/Current/Libraries"
        paths
      end

      def homebrew_extra_cmake_include_paths
        paths = []
        paths << "#{self["HOMEBREW_SDKROOT"]}/usr/include/libxml2" if libxml2_include_needed?
        paths << "#{self["HOMEBREW_SDKROOT"]}/usr/include/apache2" if MacOS::Xcode.without_clt?
        paths << "#{self["HOMEBREW_SDKROOT"]}/System/Library/Frameworks/OpenGL.framework/Versions/Current/Headers"
        paths
      end

      def homebrew_extra_cmake_library_paths
        brew_sdkroot = self["HOMEBREW_SDKROOT"]
        [Pathname("#{brew_sdkroot}/System/Library/Frameworks/OpenGL.framework/Versions/Current/Libraries")]
      end

      def homebrew_extra_cmake_frameworks_paths
        paths = []
        paths << "#{self["HOMEBREW_SDKROOT"]}/System/Library/Frameworks" if MacOS::Xcode.without_clt?
        paths
      end

      def determine_cccfg
        s = +""
        # Fix issue with >= Mountain Lion apr-1-config having broken paths
        s << "a"
        s.freeze
      end

      # @private
      def setup_build_environment(formula: nil, cc: nil, build_bottle: false, bottle_arch: nil,
                                  testing_formula: false, debug_symbols: false)
        sdk = formula ? MacOS.sdk_for_formula(formula) : MacOS.sdk
        is_xcode_sdk = sdk&.source == :xcode

        if is_xcode_sdk || MacOS.sdk_root_needed?
          Homebrew::Diagnostic.checks(:fatal_setup_build_environment_checks)
          self["HOMEBREW_SDKROOT"] = sdk.path if sdk
        end

        self["HOMEBREW_DEVELOPER_DIR"] = if is_xcode_sdk
          MacOS::Xcode.prefix.to_s
        else
          MacOS::CLT::PKG_PATH
        end

        # This is a workaround for the missing `m4` in Xcode CLT 15.3, which was
        # reported in FB13679972. Apple has fixed this in Xcode CLT 16.0.
        # See https://github.com/Homebrew/homebrew-core/issues/165388
        if deps.none? { |d| d.name == "m4" } &&
           MacOS.active_developer_dir == MacOS::CLT::PKG_PATH &&
           !File.exist?("#{MacOS::CLT::PKG_PATH}/usr/bin/m4") &&
           (gm4 = ::DevelopmentTools.locate("gm4").to_s).present?
          self["M4"] = gm4
        end

        super

        # Filter out symbols known not to be defined since GNU Autotools can't
        # reliably figure this out with Xcode 8 and above.
        if MacOS.version == "10.12" && MacOS::Xcode.version >= "9.0"
          %w[fmemopen futimens open_memstream utimensat].each do |s|
            ENV["ac_cv_func_#{s}"] = "no"
          end
        elsif MacOS.version == "10.11" && MacOS::Xcode.version >= "8.0"
          %w[basename_r clock_getres clock_gettime clock_settime dirname_r
             getentropy mkostemp mkostemps timingsafe_bcmp].each do |s|
            ENV["ac_cv_func_#{s}"] = "no"
          end

          ENV["ac_cv_search_clock_gettime"] = "no"

          # works around libev.m4 unsetting ac_cv_func_clock_gettime
          ENV["ac_have_clock_syscall"] = "no"
        end

        # On macOS Sonoma (at least release candidate), iconv() is generally
        # present and working, but has a minor regression that defeats the
        # test implemented in gettext's configure script (and used by many
        # gettext dependents).
        ENV["am_cv_func_iconv_works"] = "yes" if MacOS.version == "14"

        # The tools in /usr/bin proxy to the active developer directory.
        # This means we can use them for any combination of CLT and Xcode.
        self["HOMEBREW_PREFER_CLT_PROXIES"] = "1"

        # Deterministic timestamping.
        # This can work on older Xcode versions, but they contain some bugs.
        # Notably, Xcode 10.2 fixes issues where ZERO_AR_DATE affected file mtimes.
        # Xcode 11.0 contains fixes for lldb reading things built with ZERO_AR_DATE.
        self["ZERO_AR_DATE"] = "1" if MacOS::Xcode.version >= "11.0" || MacOS::CLT.version >= "11.0"

        # Pass `-no_fixup_chains` whenever the linker is invoked with `-undefined dynamic_lookup`.
        # See: https://github.com/python/cpython/issues/97524
        #      https://github.com/pybind/pybind11/pull/4301
        no_fixup_chains

        # Strip build prefixes from linker where supported, for deterministic builds.
        append_to_cccfg "o" if ::DevelopmentTools.ld64_version >= 512

        # Pass `-ld_classic` whenever the linker is invoked with `-dead_strip_dylibs`
        # on `ld` versions that don't properly handle that option.
        return unless ::DevelopmentTools.ld64_version.between?("1015.7", "1022.1")

        append_to_cccfg "c"
      end

      def no_weak_imports
        append_to_cccfg "w" if no_weak_imports_support?
      end

      def no_fixup_chains
        append_to_cccfg "f" if no_fixup_chains_support?
      end
    end
  end
end

Superenv.singleton_class.prepend(OS::Mac::Superenv::ClassMethods)
Superenv.prepend(OS::Mac::Superenv)
