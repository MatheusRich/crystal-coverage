class Coverage::CoverallOutputter < Coverage::Outputter
  def initialize
    @service_job_id = (ENV["TRAVIS_JOB_ID"]? || Time.now.epoch.to_s)
    @service_name = ENV["TRAVIS"]? ? "travis-ci" : "dev"
  end

  private def get_file_list(files, json, io)
    json.array do
      files.each do |file|
        json.object do
          json.field "name", file.path
          json.field "source_digest", file.md5
          json.field "coverage" do
            json.array do
              h = {} of Int32 => Int32?

              file.source_map.each_with_index { |line, idx| h[line] = file.access_map[idx] }

              max_line = file.source_map.max
              max_line.times.map { |x| h[x]? }.each { |x|
                x.nil? ? json.null : json.number(x)
              }
            end
          end
        end
      end
    end
  end

  def output(files : Array(Coverage::File), io)
    io << JSON.build do |json|
      json.object do
        json.field "service_job_id", @service_job_id
        json.field "service_name", @service_name
        json.field "source_files" do
          get_file_list(files, json, io)
        end
      end
    end
  end
end