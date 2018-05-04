
require 'benchmark'

require 'tzinfo'
require 'et-orbi'

n = 10_000

p ENV['TZ']
p EtOrbi.determine_local_tzone
p EtOrbi.send(:determine_local_tzones)

A = [
  'ENV["TZ"]',
  proc do
    ENV['TZ']
  end ]

B = [
  'EtOrbi.os_tz',
  proc do
    EtOrbi.os_tz
  end ]

C = [
  'TZInfo::Timezone.get("xxx")',
  proc do
    ::TZInfo::Timezone.get('America/Los_Angeles')
  end ]

D = [
  'EtOrbi.determine_local_tzone',
  proc do
    EtOrbi.determine_local_tzone
  end ]

E = [
  'TZInfo::Timezone.all',
  proc do
    #::TZInfo::Timezone.all
  end ]

puts
puts "Ruby #{RUBY_VERSION}p#{RUBY_PATCHLEVEL} (#{RUBY_RELEASE_DATE}) [#{RUBY_PLATFORM}]"
puts `uname -a`
puts
puts "the smaller the better"
puts

2.times do

  Benchmark.bmbm do |bm|
    bm.report(A[0]) { n.times(&A[1]) }
    bm.report(B[0]) { n.times(&B[1]) }
    bm.report(C[0]) { n.times(&C[1]) }
    bm.report(D[0]) { n.times(&D[1]) }
    bm.report(E[0]) { n.times(&E[1]) }
  end

  puts
end

## Iterations Per Second Testing
## gem install benchmark-ips
#require 'benchmark/ips'
#
#Benchmark.ips do |ips|
#  ips.report('Version A') do
#    # Code to benchmark
#  end
#
#  ips.report('Version B') do
#    # Code to benchmark
#  end
#end
