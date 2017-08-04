module TerraformDevKit
  def self.with_retry(retry_count, sleep_time: 1)
    yield
  rescue
    unless (retry_count -= 1).zero?
      sleep(sleep_time)
      retry
    end
    raise
  end
end
