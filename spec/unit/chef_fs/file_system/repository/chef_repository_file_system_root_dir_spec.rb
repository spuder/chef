require "spec_helper"
require "chef/chef_fs/file_system/repository/chef_repository_file_system_root_dir"

describe Chef::ChefFS::FileSystem::Repository::ChefRepositoryFileSystemRootDir do
  let(:tmp_path) { Dir.mktmpdir }
  let(:nodes_path) { File.join(tmp_path, "nodes") }
  let(:child_paths) { { "nodes" => [nodes_path] } }
  let(:root_dir) { described_class.new(child_paths) }

  describe "#create_child" do
    let(:dir) { double("Chef::Resource::Directory") }
    let(:context) { double("Chef::RunContext") }
    let(:owner) { "test-user" }

    before do
      allow(Chef::Resource::Directory).to receive(:new) { dir }
      allow(Chef::RunContext).to receive(:new) { context }
      allow(dir).to receive(:mode)
      allow(dir).to receive(:rights)
      allow(dir).to receive(:inherits)
      allow(dir).to receive(:run_action)
      allow(ENV).to receive(:[]).and_call_original
      allow(ENV).to receive(:[]).with("USERNAME") { owner }
    end

    context "when creating the nodes directory" do
      it "creates the directory" do
        expect(Chef::Resource::Directory).to receive(:new).with(nodes_path, context)
        expect(dir).to receive(:run_action).with(:create)
        root_dir.create_child("nodes")
      end

      describe "permissions" do
        describe "on unix", :unix_only do
          it "sets them correctly" do
            expect(dir).to receive(:mode).with(0700)
            root_dir.create_child("nodes")
          end
        end

        describe "on windows", :windows_only do
          it "sets them correctly" do
            expect(dir).to receive(:rights).with(:full_control, owner)
            expect(dir).to receive(:inherits).with(false)
            root_dir.create_child("nodes")
          end
        end
      end
    end
  end
end
