# typed: strict
# frozen_string_literal: true

require "macos_version"

FORMULA_COMPONENT_PRECEDENCE_LIST = T.let([
  [{ name: :include,   type: :method_call }],
  [{ name: :desc,      type: :method_call }],
  [{ name: :homepage,  type: :method_call }],
  [{ name: :url,       type: :method_call }],
  [{ name: :mirror,    type: :method_call }],
  [{ name: :version,   type: :method_call }],
  [{ name: :sha256,    type: :method_call }],
  [{ name: :license, type: :method_call }],
  [{ name: :revision, type: :method_call }],
  [{ name: :version_scheme, type: :method_call }],
  [{ name: :head,      type: :method_call }],
  [{ name: :stable,    type: :block_call }],
  [{ name: :livecheck, type: :block_call }],
  [{ name: :no_autobump!, type: :method_call }],
  [{ name: :bottle, type: :block_call }],
  [{ name: :pour_bottle?, type: :block_call }],
  [{ name: :head,      type: :block_call }],
  [{ name: :bottle,    type: :method_call }],
  [{ name: :keg_only,  type: :method_call }],
  [{ name: :option,    type: :method_call }],
  [{ name: :deprecated_option, type: :method_call }],
  [{ name: :deprecate!, type: :method_call }],
  [{ name: :disable!, type: :method_call }],
  [{ name: :depends_on, type: :method_call }],
  [{ name: :uses_from_macos, type: :method_call }],
  [{ name: :on_macos, type: :block_call }],
  *MacOSVersion::SYMBOLS.keys.map do |os_name|
    [{ name: :"on_#{os_name}", type: :block_call }]
  end,
  [{ name: :on_system, type: :block_call }],
  [{ name: :on_linux, type: :block_call }],
  [{ name: :on_arm, type: :block_call }],
  [{ name: :on_intel, type: :block_call }],
  [{ name: :conflicts_with, type: :method_call }],
  [{ name: :skip_clean, type: :method_call }],
  [{ name: :cxxstdlib_check, type: :method_call }],
  [{ name: :link_overwrite, type: :method_call }],
  [{ name: :fails_with, type: :method_call }, { name: :fails_with, type: :block_call }],
  [{ name: :go_resource, type: :block_call }, { name: :resource, type: :block_call }],
  [{ name: :patch, type: :method_call }, { name: :patch, type: :block_call }],
  [{ name: :needs, type: :method_call }],
  [{ name: :allow_network_access!, type: :method_call }],
  [{ name: :deny_network_access!, type: :method_call }],
  [{ name: :install, type: :method_definition }],
  [{ name: :post_install, type: :method_definition }],
  [{ name: :caveats, type: :method_definition }],
  [{ name: :plist_options, type: :method_call }, { name: :plist, type: :method_definition }],
  [{ name: :test, type: :block_call }],
].freeze, T::Array[T::Array[{ name: Symbol, type: Symbol }]])
