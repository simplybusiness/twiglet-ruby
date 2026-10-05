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

  # A shipped .rbs with no lib/ counterpart declares somebody else's type.
  external = shipped_sigs.reject { |f| sources.include?(f.sub(%r{\Asig/}, 'lib/').sub(/\.rbs\z/, '.rb')) }

  it 'adds nothing to types it does not own' do
    # Anything we put inside an external type - a method, attribute, alias, constant, mixin - is
    # a hard error in the build of a consumer who declares it too, so these stubs may hold only
    # empty nested types.
    refute_empty external, 'expected at least one external stub, or this test proves nothing'

    external.each do |file|
      buffer = RBS::Buffer.new(name: file, content: File.read(File.join(root, file)))
      decls = RBS::Parser.parse_signature(buffer).last # [buffer, directives, declarations]
      offenders = declared_members(decls).map { |m| m.class.name.split('::').last }
      assert_empty offenders, "#{file} declares #{offenders.join(', ')} on a type we do not own"
    end
  end

  it 'declares external types with the same kind and superclass as their owner' do
    # A class declared as a module, or with a different superclass, is a hard error in the
    # build of a consumer who declares the type correctly, even with no members on either side.
    external.each do |file|
      require File.basename(file, '.rbs') # stubs are named after the gem they cover

      buffer = RBS::Buffer.new(name: file, content: File.read(File.join(root, file)))
      declared_types(RBS::Parser.parse_signature(buffer).last).each do |name, decl|
        actual = Object.const_get(name)
        if decl.is_a?(RBS::AST::Declarations::Class)
          assert_kind_of Class, actual, "#{file} declares #{name} as a class, but it is a module"
          if decl.super_class
            assert_equal actual.superclass, Object.const_get(decl.super_class.name.to_s),
                         "#{file} declares the wrong superclass for #{name}"
          end
        else
          refute_kind_of Class, actual, "#{file} declares #{name} as a module, but it is a class"
        end
      end
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

  def declared_types(decls, namespace = nil)
    decls.flat_map do |decl|
      next [] unless decl.is_a?(RBS::AST::Declarations::Class) || decl.is_a?(RBS::AST::Declarations::Module)

      name = [namespace, decl.name.to_s].compact.join('::')
      [[name, decl], *declared_types(decl.members, name)]
    end
  end
end
