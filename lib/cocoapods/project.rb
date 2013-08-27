require 'xcodeproj'

module Pod

  # The Pods project.
  #
  # Model class which provides helpers for working with the Pods project
  # through the installation process.
  #
  class Project < Xcodeproj::Project

    # @return [Sandbox] the sandbox which returns the information about which
    #         Pods are local.
    #
    attr_reader :sandbox

    # @param  [Sandbox] sandbox @see #sandbox
    #
    def initialize(sandbox)
      super(sandbox.project_path)
      @sandbox = sandbox
      @support_files_group = new_group('Targets Support Files')
      @refs_by_absolute_path = {}
    end

    # @return [Pathname] the directory where the project is stored.
    #
    def root
      @root ||= path.dirname
    end

    # @return [String] a string representation suited for debugging.
    #
    def inspect
      "#<#{self.class}> path:#{path}"
    end


    public

    # @!group Groups
    #-------------------------------------------------------------------------#

    # @return [PBXGroup] the group where the support files for the Pod
    #         libraries should be added.
    #
    attr_reader :support_files_group

    # Returns the `Pods` group, creating it if needed.
    #
    # @return [PBXGroup] the group.
    #
    def pods
      @pods ||= new_group('Pods')
    end

    # Returns the `Local Pods` group, creating it if needed. This group is used
    # to contain locally sourced pods.
    #
    # @return [PBXGroup] the group.
    #
    def local_pods
      @local_pods ||= new_group('Local Pods')
    end

    # @return [PBXGroup] the group for the spec with the given name.
    #
    def group_for_spec(spec_name, type = nil)
      local = sandbox.local?(spec_name)
      parent_group = local ? local_pods : pods
      spec_group = add_spec_group(spec_name, parent_group)
      if type
        case type
        when :source_files then sub_group = 'Source Files'
        when :resources then sub_group = 'Resources'
        when :frameworks_and_libraries then sub_group = 'Frameworks & Libraries'
        when :support_files then sub_group = 'Support Files'
        else raise "[BUG]"
        end
        spec_group.find_subpath(sub_group, true)
      else
        spec_group
      end
    end


    public

    # @!group File references
    #-------------------------------------------------------------------------#

    # Adds a file reference for each one of the given files in the specified
    # group, namespaced by specification unless a file reference for the given
    # path already exits.
    #
    # @note   With this set-up different subspecs might not reference the same
    #         file (i.e. the first will win). Not sure thought if this is a
    #         limitation or a feature.
    #
    # @param  [Array<Pathname,String>] paths
    #         The files for which the file reference is needed.
    #
    # @param  [String] spec_name
    #         The full name of the specification.
    #
    # @param  [PBXGroup] parent_group
    #         The group where the file references should be added.
    #
    # @return [void]
    #
    def add_file_reference(absolute_path, group)
      # existing = file_reference(absolute_paths)
      # unless existing
      absolute_path = Pathname.new(absolute_path)
      ref = group.new_file(absolute_path)
      @refs_by_absolute_path[absolute_path] = ref
      # end
    end

    # Returns the file reference for the given absolute file path.
    #
    # @param  [Pathname,String] absolute_path
    #         The absolute path of the file whose reference is needed.
    #
    # @return [PBXFileReference] The file reference.
    # @return [Nil] If no file reference could be found.
    #
    def file_reference(absolute_path)
      absolute_path = Pathname.new(absolute_path)
      refs_by_absolute_path[absolute_path]
    end

    # Adds a file reference to the podfile.
    #
    # @param  [Pathname,String] podfile_path
    #         The path of the Podfile.
    #
    # @return [PBXFileReference] The file reference.
    #
    def add_podfile(podfile_path)
      podfile_path = Pathname.new(podfile_path)
      podfile_ref = new_file(podfile_path)
      podfile_ref.xc_language_specification_identifier = 'xcode.lang.ruby'
      podfile_ref.last_known_file_type = 'text'
      podfile_ref
    end


    private

    # @!group Private helpers
    #-------------------------------------------------------------------------#

    # @return [Hash{Pathname => PBXFileReference}] The file references grouped
    #         by absolute path.
    #
    attr_reader :refs_by_absolute_path

    # Returns a subgroup of the give group for the given spec creating it if
    # needed.
    #
    # @param  [String] spec_name
    #         The full name of the specification.
    #
    # @param  [PBXGroup] root_group
    #         The group where to add the specification. Either `Pods` or `Local
    #         Pods`.
    #
    # @return [PBXGroup] The group for the spec with the given name.
    #
    def add_spec_group(spec_name, root_group)
      current_group = root_group
      group = nil
      spec_name.split('/').each do |name|
        group = current_group[name] || current_group.new_group(name)
        current_group = group
      end
      group
    end

    #-------------------------------------------------------------------------#

  end
end
