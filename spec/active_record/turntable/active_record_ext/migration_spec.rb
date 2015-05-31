require 'spec_helper'

describe ActiveRecord::Turntable::Migration do
  before(:all) do
    reload_turntable!(File.join(File.dirname(__FILE__), "../../../config/turntable.yml"))
  end

  before(:each) do
    establish_connection_to(:test)
    truncate_shard
  end

  describe ".target_shard?" do
    subject { migration_class.new.target_shard?('user_shard_1') }

    context "With master server" do
      let (:migration_class) {
        klass = Class.new(ActiveRecord::Migration){}
      }
      it { is_expected.to eq false }
    end

    context "With shard servers" do
      let (:migration_class) {
        klass = Class.new(ActiveRecord::Migration){
          clusters :mod_cluster
        }
      }
      it { is_expected.to eq true }
    end

    context "With a shard server" do
      let (:migration_class) {
        klass = Class.new(ActiveRecord::Migration){
          shards "user_shard_1"
        }
      }
      it { is_expected.to eq true }
    end
  end

  describe ".target_master_only?" do

    context "When master only migration and current_shard is not in shards" do
      let (:migration_class) {
        klass = Class.new(ActiveRecord::Migration){}
        klass.new
      }
      it {
        expect(migration_class.target_master_only?(nil)).to eq true
      }
    end

    context "When master only migration and current_shard is in shards" do
      let (:migration_class) {
        klass = Class.new(ActiveRecord::Migration){}
        klass.new
      }
      it {
        expect(migration_class.target_master_only?("user_shard_1")).to eq false
      }
    end

    context "When migration for shards and current_shard is not in shards" do
      let (:migration_class) {
        klass = Class.new(ActiveRecord::Migration){
          clusters :mod_cluster
        }
        klass.new
      }
      it {
        expect(migration_class.target_master_only?(nil)).to eq false
      }
    end

    context "When migration for shards and current_shard is in shards" do
     let (:migration_class) {
        klass = Class.new(ActiveRecord::Migration){
          clusters :mod_cluster
        }
        klass.new
      }
      it {
        expect(migration_class.target_master_only?("user_shard_1")).to eq false
      }
    end
  end

  describe ".exec_migration_without_turntable?" do

    context "With migration for master only" do
      let (:migration_class) {
        klass = Class.new(ActiveRecord::Migration){}
        klass.new
      }
      context "When current_shard is not in shards" do
        it {
          migration_class.current_shard = nil
          expect(migration_class.exec_migration_without_turntable?).to eq true
        }
      end
      context "When current_shard is in shards" do
        it {
          migration_class.current_shard = "user_shard_1"
          expect(migration_class.exec_migration_without_turntable?).to eq false
        }
      end
    end

    context "With migration for master only" do
      let (:migration_class) {
        klass = Class.new(ActiveRecord::Migration){
          clusters :mod_cluster
        }
        klass.new
      }
      context "When current_shard is not in shards" do
        it {
          migration_class.current_shard = nil
          expect(migration_class.exec_migration_without_turntable?).to eq true
        }
      end
      context "When current_shard is in shards" do
        it {
          migration_class.current_shard = "user_shard_1"
          expect(migration_class.exec_migration_without_turntable?).to eq true
        }
      end
    end

  end

  describe ".target_shards" do
    subject { migration_class.new.target_shards }

    context "With clusters definitions" do
      let(:migration_class) {
        klass = Class.new(ActiveRecord::Migration) {
        clusters :user_cluster
        }
      }
      let(:cluster_config) { ActiveRecord::Base.turntable_config["clusters"]["user_cluster"] }
      let(:user_cluster_shards) { cluster_config["shards"].map { |s| s["connection"] } }

      it { is_expected.to eq(user_cluster_shards) }
    end

    context "With clusters definitions for mysql sequence type" do
      let(:migration_class) {
        klass = Class.new(ActiveRecord::Migration) {
        clusters :mod_cluster
        }
      }
      let(:cluster_config) { ActiveRecord::Base.turntable_config["clusters"]["mod_cluster"] }
      let(:user_cluster_shards) { cluster_config["shards"].map { |s| s["connection"] } }
      let(:user_cluster_seq)    { cluster_config["seq"].keys.map { |key| cluster_config["seq"][key]["connection"] } }

      it { is_expected.to eq([user_cluster_shards + user_cluster_seq].flatten) }
    end

    context "With shards definitions" do
      let(:migration_class) {
        klass = Class.new(ActiveRecord::Migration) {
          shards "user_shard_1"
        }
      }

      it { is_expected.to eq(["user_shard_1"]) }
    end
  end
end
