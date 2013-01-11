# coding: utf-8

require 'spec_helper'
feature 'スタンザを表示する' do
  context 'General Summary スタンザ' do
    scenario "遺伝子 sll1615" do
      visit stanza_path('general_summary', stanza_params: {gene_id: 'sll1615'})

      expect(page).to have_text('tRNA modification GTPase TrmE')
      expect(page).to have_text('trmE')
      expect(page).to have_text('mnmE; thdF')
    end
  end

  context 'Transcript Attributes スタンザ' do
    scenario "遺伝子 sll1615" do
      visit stanza_path('transcript_attributes', stanza_params: {gene_id: 'sll1615'})

      expect(page).to have_text('1455753')
      expect(page).to have_text('1457123')
    end
  end

  context 'Gene Attributes スタンザ' do
    scenario "遺伝子 slr1311 / taxid: 1148" do
      visit stanza_path('gene_attributes', stanza_params: {gene_id: 'slr1311', tax_id: '1148'})

      expect(page).to have_text('photosystem II D1 protein')
      expect(page).to have_text('psbA2')
      expect(page).to have_text('MTTTLQQRESASLWEQFCQWVTSTNNRIYVGWFGTLMIPTLLTATTCFIIAFIAAPPVDIDGIREPVAGSLLYGNNIISGAVVPSSNAIGLHFYPIWEAASLDEWLYNGGPYQLVVFHFLIGIFCYMGRQWELSYRLGMRPWICVAYSAPVSAATAVFLIYPIGQGSFSDGMPLGISGTFNFMIVFQAEHNILMHPFHMLGVAGVFGGSLFSAMHGSLVTSSLVRETTEVESQNYGYKFGQEEETYNIVAAHGYFGRLIFQYASFNNSRSLHFFLGAWPVIGIWFTAMGVSTMAFNLNGFNFNQSILDSQGRVIGTWADVLNRANIGFEVMHERNAHNFPLDLASGEQAPVALTAPAVNG
')
      expect(page).to have_text('7229..8311')
      expect(page).to have_text('http://purl.uniprot.org/refseq/NP_439906.1')
    end
  end
end
