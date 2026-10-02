require 'minitest/autorun'
require 'open3'
require 'rbs'

# Asserts the gemspec's own file list, which is what `gem build` packages, so these hold
# for whatever builds the gem rather than for one workflow.
describe 'packaged RBS signatures' do
  root = File.expand_path('..', __dir__)
  packaged = Gem::Specification.load(File.join(root, 'twiglet.gemspec')).files
  sources = Dir.chdir(root) { Dir.glob('lib/**/*.rb') }
  shipped_sigs = packaged.grep(/\.rbs\z/)

  it 'has sources to sign' do
    # Without this the tests below pass vacuously.
    refute_empty sources
  end

  it 'ships a signature for every source file' do
    expected = sources.map { |f| f.sub(%r{\Alib/}, 'sig/').sub(/\.rb\z/, '.rbs') }
    assert_empty expected - packaged
  end

  it 'ships the manifest naming our stdlib dependencies' do
    # Without it a consumer's `rbs collection` does not learn our stdlib dependencies, and
    # Twiglet::Logger's superclass stops resolving for them.
    assert_includes packaged, 'sig/manifest.yaml'
  end

  it 'adds nothing to types it does not own' do
    # A shipped .rbs with no lib/ counterpart declares somebody else's type. Anything we put
    # inside it - a method, attribute, alias, constant, mixin - is a hard error in the build
    # of a consumer who declares it too, so these stubs may hold only empty nested types.
    foreign = shipped_sigs.reject { |f| sources.include?(f.sub(%r{\Asig/}, 'lib/').sub(/\.rbs\z/, '.rb')) }
    refute_empty foreign, 'expected at least one external stub, or this test proves nothing'

    foreign.each do |file|
      buffer = RBS::Buffer.new(name: file, content: File.read(File.join(root, file)))
      decls = RBS::Parser.parse_signature(buffer).last # [buffer, directives, declarations]
      offenders = declared_members(decls).map { |m| m.class.name.split('::').last }
      assert_empty offenders, "#{file} declares #{offenders.join(', ')} on a type we do not own"
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

  # Every member except a nested class or module, which is the only thing these stubs may
  # contain. Inverted rather than listing the member kinds that declare something, so a kind
  # we did not think of fails the test instead of slipping through it.
  def declared_members(decls)
    decls.flat_map do |decl|
      next [] unless decl.respond_to?(:members)

      decl.members.flat_map do |member|
        # Only Class and Module recurse. Declarations::Constant is also a Declarations::Base,
        # and it collides downstream just as a method does.
        nested = member.is_a?(RBS::AST::Declarations::Class) || member.is_a?(RBS::AST::Declarations::Module)
        nested ? declared_members([member]) : [member]
      end
    end
  end
end
