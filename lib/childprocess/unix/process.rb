module ChildProcess
  module Unix
    class Process < AbstractProcess

      def stop(timeout = 3)
        assert_started
        send_term

        begin
          return poll_for_exit(timeout)
        rescue TimeoutError
          # try next
        end

        send_kill
        wait
      rescue Errno::ECHILD
        # that'll do
        true
      end

      #
      # Did the process exit?
      #
      # @return [Boolean]
      #

      def exited?
        return true if @exit_code


        assert_started
        pid, status = ::Process.waitpid2(@pid, ::Process::WNOHANG)

        log(pid, status)

        if pid
          @exit_code = status.exitstatus || status.termsig
        end

        !!pid
      end

      private

      def wait
        @exit_code = ::Process.waitpid @pid
      end

      def send_term
        send_signal 'TERM'
      end

      def send_kill
        send_signal 'KILL'
      end

      def send_signal(sig)
        assert_started

        log "sending #{sig}"
        ::Process.kill sig, @pid
      end

      def launch_process
        @pid = fork {
          unless $DEBUG
            [STDOUT, STDERR].each { |io| io.reopen("/dev/null") }
          end

          exec(*@args)
        }
      end

    end # Process
  end # Unix
end # ChildProcess