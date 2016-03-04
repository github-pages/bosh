module Bosh
  module Director
    class DependencyKeyGenerator
      def generate_from_models(package, release_version)
        @all_packages = release_version.packages.map do |p|
          {
            'name' => p.name,
            'version' => p.version,
            'dependencies' => p.dependency_set
          }
        end

        root_package_hash = {'name' => package.name, 'version' => package.version, 'dependencies' => package.dependency_set}
        package_hashes = transitive_dependencies(root_package_hash)

        root_package_hash['dependencies'].sort.map do |dependency_name|
          arrayify(find_package_hash(dependency_name), package_hashes.dup)
        end.to_json
      end

      def generate_from_manifest(package_name, compiled_packages)
        @all_packages = compiled_packages
        package = compiled_packages.find { |package| package['name'] == package_name }
        raise ReleaseExistingPackageHashMismatch, "Package '#{package_name}' not found in the release manifest." if package.nil?

        package['dependencies'].sort.map do |dependency_name|
          arrayify(find_package_hash(dependency_name), all_packages.dup)
        end.to_json
      end

      private

      attr_reader :all_packages

      def transitive_dependencies(package)
        dependency_set = Set.new
        dependencies(package).each do |dependency|
          dependency_set << dependency
          dependency_set.merge(transitive_dependencies(dependency))
        end
        dependency_set
      end

      def dependencies(package)
        package['dependencies'].map { |package_name| find_package_hash(package_name) }.to_set
      end

      def arrayify(package, remaining_packages)
        remaining_packages.delete(package)

        [
          package['name'],
          package['version']
        ].tap do |output|
          if package['dependencies'] && package['dependencies'].length > 0
            output << package['dependencies'].map { |sub_dep| arrayify(find_package_hash(sub_dep), remaining_packages) }
          end
          output
        end
      end

      def find_package_hash(name)
        all_packages.find { |package| package['name'] == name }
      end
    end
  end
end
