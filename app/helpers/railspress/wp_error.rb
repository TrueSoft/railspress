module Railspress
  class WP_Error < StandardError

    attr_reader :errors, :error_data

    # Initialize the error.
    #
    # If `$code` is empty, the other parameters will be ignored.
    # When `$code` is not empty, `$message` will be used even if
    # it is empty. The `$data` parameter will be used only if it
    # is not empty.
    #
    # Though the class is constructed with a single error code and
    # message, multiple codes can be added using the `add()` method.
    #
    # @param [string|int] code Error code
    # @param [string] message Error message
    # @param [mixed] data Optional. Error data.
    def initialize(code = nil, message = nil, data = nil)
      return if code.blank?

      @errors = {}
      @errors[code] = message
      unless data.nil?
        @error_data[code] = data
      end
    end

    # Retrieve all error codes.
    #
    # @return array List of error codes, if available.
    def get_error_codes
      return [] unless has_errors

      @errors.keys
    end

    # Retrieve first error code available.
    #
    # @return [string|int] Empty string, if no error codes.
    def get_error_code
      codes = get_error_codes
      return '' if codes.empty?
      codes[0]
    end

    # Verify if the instance contains errors.
    #
    # @return bool
    def has_errors
      !@errors.blank?
    end
  end
end