require 'rbbt-util'
require 'rbbt/workflow'
require 'rbbt/util/docker'
require 'rbbt/sources/organism'

Misc.add_libdir if __FILE__ == $0
require 'rbbt/sources/MutSig'

Workflow.require_workflow "Study"
module MutSig
  extend Workflow

  input :maf_file, :text, "MAF File"
  input :coverage, :text, "Coverage File", nil
  input :covariates, :text, "Covariate File", nil
  input :organism, :string, "Organism code", Organism.default_code("Hsa")
  task :analysis => :tsv do |maf_file,coverage,covariates,organism|

    coverage = MutSig.exome_full192_coverage.produce.find if coverage.nil?
    covariates = MutSig.gene_covariates.produce.find if covariates.nil?
    MutSig.mutation_type_dictionary_file_ext.produce
    MutSig.exome_full192_coverage.produce

    cmd = "bash -c 'ex  -s -c /^#:/d -c s/^#// -c wq /job/maf_file ; /opt/MutSigCV_1.4/run_MutSigCV.sh /opt/mcr/v81 /job/maf_file /job/coverage /job/covariates /result/out /data/mutation_type_dictionary_file_ext /data/chr_files_hg19/'"
    TmpFile.with_file do |tmpdirectory|
      io = Docker.run('jacmarjorie/mutsig', cmd, 
                      :directory => tmpdirectory,  
                      :job_inputs => {:maf_file => maf_file, :covariates => covariates, :coverage => coverage}, 
                      :mounts => {'/data' => MutSig.root.find, '/result' => File.expand_path(file('result').find)},
                      :pipe => true )
      while line = io.gets
        line.strip!
        Log.debug line
        log :preprocess, line if line =~ /^MutSigCV: PRE/
        log :run, line if line =~ /^MutSigCV: RUN/
      end

      tsv = file('result')["out.sig_genes.txt"].tsv :header_hash => "", :type => :list
      tsv.namespace = organism
      tsv.key_field = "Associated Gene Name"
      tsv
    end
  end

end

if defined? Study
  module Study
    dep :maf_file
    dep MutSig, :analysis, :maf_file => :maf_file
    task :mut_sig => :tsv do
      TSV.get_stream step(:analysis)
    end

    dep :organism
    dep :mut_sig 
    input :threshold, :float, "Q-value significance threshold", 0.05
    task :mut_sig_significant => :array do |threshold|
      organism = step(:organism).load
      name2ensg = Organism.identifiers(organism).index :target => "Ensembl Gene ID", :persist => true, :fields => ["Associated Gene Name"]
      io = TSV.traverse step(:mut_sig), :into => :stream do |name, values|
        qvalue = values.pop()
        pvalue = values.pop()
        next unless qvalue.to_f <= threshold
        ensg = name2ensg[name]
        next if ensg.nil?
        ensg + ":" + pvalue.to_s
      end
      CMD.cmd('sort -k2 -g -t: -|cut -f 1 -d:', :in => io, :pipe => true)
    end

    dep :organism
    dep :mut_sig_significant
    dep :mappable_genes
    input :database, :string, "Database to use", nil, :select_options => Enrichment::DATABASES
    dep Enrichment, :enrichment, :organism => :organism, :list => :mut_sig_significant, :background => :mappable_genes
    task :mut_sig_significant_enrichment => :tsv do
      TSV.get_stream step(:enrichment)
    end

    dep :organism
    dep Study, :mut_sig_significant, :threshold => 1
    dep :mappable_genes
    dep Enrichment, :rank_enrichment, :organism => :organism, :list => :mut_sig_significant, :background => :mappable_genes, :permutations => 100_000
    input :database, :string, "Database to use", nil, :select_options => Enrichment::DATABASES
    task :mut_sig_rank_enrichment => :tsv do
      TSV.get_stream step(:rank_enrichment)
    end
  end

  Study.update_task_properties
end
