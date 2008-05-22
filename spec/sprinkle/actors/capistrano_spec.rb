require File.dirname(__FILE__) + '/../../spec_helper'

describe Sprinkle::Actors::Capistrano do

  before do
    @recipes = 'deploy'
    @cap = ::Capistrano::Configuration.new
    ::Capistrano::Configuration.stub!(:new).and_return(@cap)
    @cap.stub!(:load).and_return
  end

  def create_cap(&block)
    Sprinkle::Actors::Capistrano.new &block
  end

  describe 'when created' do

    it 'should create a new capistrano object' do
      ::Capistrano::Configuration.should_receive(:new).and_return(@cap)
      create_cap
    end

    it 'should set logging on the capistrano object' do
      @cap = create_cap
      @cap.config.logger.level.should == ::Capistrano::Logger::INFO
    end

    describe 'with a block' do

      before do
        @actor = create_cap do
          recipes 'cool gear' # default is deploy
        end
      end

      it 'should evaluate the block against the actor instance' do
        @actor.loaded_recipes.should include('cool gear')
      end

    end

    describe 'without a block' do

      it 'should automatically load the default capistrano configuration' do
        @cap.should_receive(:load).with('deploy').and_return
      end

      after do
        @actor = create_cap
      end

    end

  end

  describe 'recipes' do

    it 'should add the recipe location to an internal store' do
      @cap = create_cap do
        recipes 'deploy'
      end
      @cap.loaded_recipes.should == [ @recipes ]
    end

    it 'should load the given recipe' do
      @cap.should_receive(:load).with(@recipes).and_return
      create_cap
    end

  end

  describe 'processing commands' do

    before do
      @commands = %w( op1 op2 )
      @roles    = %w( app )
      @name     = 'name'

      @cap = create_cap do; recipes 'deploy'; end
      @cap.stub!(:run).and_return
    end

    it 'should dynamically create a capistrano task containing the commands' do
      @cap.config.should_receive(:task).and_return
    end

    it 'should invoke capistrano task after creation' do
      @cap.should_receive(:run).with(@name).and_return
    end

    after do
      @cap.process @name, @commands, @roles
    end

  end

  describe 'generated task' do

    before do
      @commands = %w( op1 op2 )
      @roles    = %w( app )
      @name     = 'name'

      @cap = create_cap do; recipes 'deploy'; end
      @cap.config.stub!(:fetch).and_return(:sudo)
      @cap.config.stub!(:invoke_command).and_return
    end

    it 'should use sudo to invoke commands when so configured' do
      @cap.config.should_receive(:fetch).with(:run_method, :sudo).and_return(:sudo)
    end

    it 'should run the supplied commands' do
      @cap.config.should_receive(:invoke_command).with('op1', :via => :sudo).ordered.and_return
      @cap.config.should_receive(:invoke_command).with('op2', :via => :sudo).ordered.and_return
    end

    it 'should be applicable for the supplied roles' do
      @cap.stub!(:run).and_return
      @cap.config.should_receive(:task).with(:install_name, :roles => @roles).and_return
    end

    after do
      @cap.process @name, @commands, @roles
    end

  end

end
