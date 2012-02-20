require_relative '../feature/java/merge_jar'
require_relative '../feature/java/merge_worker'

module IronWorkerNG
  module Package
    class Java < IronWorkerNG::Package::Base
      include IronWorkerNG::Feature::Java::MergeJar::InstanceMethods
      include IronWorkerNG::Feature::Java::MergeWorker::InstanceMethods

      def create_runner(zip, init_code)
        classpath_array = []
      
        @features.each do |f|
          if f.respond_to?(:code_for_classpath)
            classpath_array << f.send(:code_for_classpath)
          end
        end

        classpath = classpath_array.join(':')
      
        zip.get_output_stream('runner.rb') do |runner|
          runner.write <<RUNNER
# IronWorker NG #{File.read(File.dirname(__FILE__) + '/../../../VERSION').gsub("\n", '')}

root = nil

($*.size - 2).downto(0) do |i|
  root = $*[i + 1] if $*[i] == '-d'
end

Dir.chdir(root)

#{init_code}

puts `java -cp #{classpath} #{worker.klass} \#{$*.join(' ')}`
RUNNER
        end
      end

      def runtime
        'ruby'
      end

      def runner
        'runner.rb'
      end
    end
  end
end

IronWorkerNG::Package::Base.register_type(:name => 'java', :klass => IronWorkerNG::Package::Java)
