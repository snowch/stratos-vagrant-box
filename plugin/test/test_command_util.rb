require 'test/unit'
require 'command_util'

class CommandTest < Test::Unit::TestCase

  def test_run_command
    StratosUtil.run_command('echo hello')
  end

  def test_run_command_with_failure
    assert_raise RuntimeError do
       StratosUtil.run_command('/bin/bash -c "exit 1"')
    end
  end
end
