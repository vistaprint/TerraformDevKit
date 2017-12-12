require 'TerraformDevKit/environment'
require 'TerraformDevKit/terraform_template_config_file'

TDK = TerraformDevKit

RSpec.describe TerraformDevKit::TerraformTemplateConfigFile do
  context 'with local backend' do
    let(:env_name) { 'dummyenv' }
    let(:env) { TDK::Environment.new(env_name) }

    context 'with no region' do
      let(:aws_config) { {} }
      let(:project)  {{}}

      it 'raises an error' do
        expect {
          TDK::TerraformTemplateConfigFile.new(
            '', project, env, aws_config
          ).render
        }.to raise_error(KeyError)
      end
    end

    context 'with no profile' do
      let(:aws_config) { { 'region' => 'dummyregion' } }
      let(:project) do
        double(name: 'dummy-project', acronym: 'DP')
      end
      let(:input) do
        %(
          variable "profile" {
            {{#Profile}}default = "{{Profile}}"{{/Profile}}
          }
        )
      end

      let(:expected_output) do
        %(
          variable "profile" {
            default = ""
          }
        )
      end

      it 'renders an empty default profile' do
        output = TDK::TerraformTemplateConfigFile.new(
          input, project, env, aws_config
        ).render
        expect(output).to eq(expected_output)
      end
    end

    context 'with a profile' do
      let(:aws_config) do
        {
          'profile' => 'dummyprofile',
          'region' => 'dummyregion'
        }
      end
      let(:project) do
        double(name: 'dummy-project', acronym: 'DP')
      end
      let(:input) do
        %(
          variable "profile" {
            {{#Profile}}default = "{{Profile}}"{{/Profile}}
          }
        )
      end

      let(:expected_output) do
        %(
          variable "profile" {
            default = "dummyprofile"
          }
        )
      end

      it 'renders the profile' do
        output = TDK::TerraformTemplateConfigFile.new(
          input, project, env, aws_config
        ).render
        expect(output).to eq(expected_output)
      end
    end

    context 'with all the required inputs' do
      let(:aws_config) do
        {
          'profile' => 'dummyprofile',
          'region' => 'dummyregion'
        }
      end      
      let(:project) do
        double(name: 'dummy-project', acronym: 'DP')
      end
      let(:input) do
        %(
          variable "profile" {
            {{#Profile}}default = "{{Profile}}"{{/Profile}}
          }

          locals {
            region = "{{Region}}"
            env = "{{Environment}}"
          }

          terraform {
            backend
            {{#LocalBackend}}"local"{{/LocalBackend}}{{^LocalBackend}}"s3"{{/LocalBackend}}
          }
        )
      end

      let(:expected_output) do
        %(
          variable "profile" {
            default = "dummyprofile"
          }

          locals {
            region = "dummyregion"
            env = "dummyenv"
          }

          terraform {
            backend
            "local"
          }
        )
      end

      it 'renders the template with all the values' do
        output = TDK::TerraformTemplateConfigFile.new(
          input, project, env, aws_config
        ).render
        expect(output).to eq(expected_output)
      end
    end
  end

  context 'with remote backend' do
    let(:env_name) { 'prod' }
    let(:env) { TDK::Environment.new(env_name) }    
    let(:project) do
      double(name: 'dummy-project', acronym: 'DP')
    end
    let(:aws_config) do
      {
        'profile' => 'dummyprofile',
        'region' => 'dummyregion'
      }
    end
    let(:input) do
      %(
        variable "profile" {
          {{#Profile}}default = "{{Profile}}"{{/Profile}}
        }

        locals {
          region = "{{Region}}"
          env = "{{Environment}}"
        }
        
        terraform {
          backend "s3" {
            bucket         = {{ProjectName}}
            key            = "{{ProjectAcronym}}-{{Environment}}.tfstate"
            dynamodb_table = "{{ProjectAcronym}}-{{Environment}}-lock-table"
            encrypt        = true
            profile        = "{{Profile}}"
            region         = "{{Region}}"
          }
        }
      )
    end

    let(:expected_output) do
      %(
        variable "profile" {
          default = "dummyprofile"
        }

        locals {
          region = "dummyregion"
          env = "prod"
        }
        
        terraform {
          backend "s3" {
            bucket         = dummy-project
            key            = "DP-prod.tfstate"
            dynamodb_table = "DP-prod-lock-table"
            encrypt        = true
            profile        = "dummyprofile"
            region         = "dummyregion"
          }
        }
      )
    end

    it 'renders the template with all the values' do
      output = TDK::TerraformTemplateConfigFile.new(
        input, project, env, aws_config
      ).render
      expect(output).to eq(expected_output)
    end
  end

  context 'with extra values' do
    let(:env_name) { 'dummyenv' }
    let(:env) { TDK::Environment.new(env_name) }    
    let(:project) do
      double(name: 'dummy-project', acronym: 'DP')
    end
    let(:aws_config) do
      {
        'profile' => 'dummyprofile',
        'region' => 'dummyregion'
      }
    end
    let(:input) do
      %(
        locals {
          dummy_var = "{{DummyVar}}"
        }
      )
    end

    let(:expected_output) do
      %(
        locals {
          dummy_var = "FooBar"
        }
      )
    end

    it 'renders the extra values' do
      output = TDK::TerraformTemplateConfigFile.new(
        input, project, env, aws_config, extra_vars: { DummyVar: 'FooBar' }
      ).render
      expect(output).to eq(expected_output)
    end
  end
end
