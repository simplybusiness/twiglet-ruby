require 'minitest/autorun'
require 'open3'
require 'rbs'

# The gem's RBS contract with its consumers.
#
# The signatures under sig/ were added in 9e4f512 but never shipped: gem.files did not name
# them, so every release contained no RBS at all and downstream projects hand-wrote stubs
# for Twiglet::Logger. Nothing failed to make that visible - the gem was simply empty.
# These tests assert against the gemspec's own file list, which is what `gem build`
# packages, so they hold for whatever builds the gem rather than for one workflow.
describe 'packaged RBS signatures' do
  root = File.expand_path('..', __dir__)
  packaged = Gem::Specification.load(File.join(root, 'twiglet.gemspec')).files
  sources = Dir.chdir(root) { Dir.glob('lib/**/*.rb') }
  shipped_sigs = packaged.grep(/\.rbs\z/)

  it 'has sources to sign' do
    # Guards the tests below: with no sources they would pass vacuously.
    refute_empty sources
  end

  it 'ships a signature for every source file' do
    expected = sources.map { |f| f.sub(%r{\Alib/}, 'sig/').sub(/\.rb\z/, '.rbs') }
    assert_empty expected - packaged
  end

  it 'ships the manifest naming our stdlib dependencies' do
    # Without it a consumer's `rbs collection` does not know this gem needs logger, json
    # and time, and Twiglet::Logger's superclass stops resolving for them.
    assert_includes packaged, 'sig/manifest.yaml'
  end

  it 'declares no methods on types it does not own' do
    # A shipped .rbs with no lib/ counterpart is a stub for somebody else's type. RBS lets a
    # consumer reopen a class we declare, but a method we declare and they also declare is a
    # hard RBS::DuplicatedMethodDefinition that fails their build. json-schema ships no RBS
    # and is absent from gem_rbs_collection, so a consumer type-checking against it has
    # written stubs of their own and would collide with ours.
    foreign = shipped_sigs.reject { |f| sources.include?(f.sub(%r{\Asig/}, 'lib/').sub(/\.rbs\z/, '.rb')) }
    refute_empty foreign, 'expected at least one external stub, or this test proves nothing'

    foreign.each do |file|
      buffer = RBS::Buffer.new(name: file, content: File.read(File.join(root, file)))
      decls = RBS::Parser.parse_signature(buffer).last # [buffer, directives, declarations]
      assert_empty method_names(decls), "#{file} declares methods on a type we do not own"
    end
  end

  it 'ships signatures that resolve on their own' do
    # -r mirrors sig/manifest.yaml: the stdlib a consumer's RBS setup resolves for us.
    out, status = Dir.chdir(root) do
      Open3.capture2e(
        'bundle', 'exec', 'rbs', '--no-collection',
        '-r', 'logger', '-r', 'json', '-r', 'time', '-I', 'sig', 'validate'
      )
    end
    assert status.success?, "shipped signatures do not resolve on their own:\n#{out}"
  end

  def method_names(decls)
    decls.flat_map do |decl|
      next [] unless decl.respond_to?(:members)

      decl.members.flat_map do |member|
        case member
        when RBS::AST::Members::MethodDefinition then [member.name]
        when RBS::AST::Declarations::Base then method_names([member])
        else []
        end
      end
    end
  end
end
