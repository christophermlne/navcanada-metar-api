defmodule MetarScraper.Region do
 @regions %{
    arctic:              ~w(CYLT CWGZ CYAB CYGZ CWEU CYIO CYEU CYRB),
    atlantic:            ~w(CYBC CYFT CZBF CYMH CWKW CYQM CWYK CYYY CWCA CYDP CYCA CYNA CYYG CYPD CZUM CWSA CYDF CSB2 CYFC CST5 CYCX CWZZ CYQX CYSJ CYGP LFVP CYYR CYZV CYZX CYAY CYAW CYYT CYHZ CYSL CYGV CYJT CYGR CYQY CYLU CWTU CWWU CYWK CCX2 CYQI CYBX),
    ontario_quebec:      ~w(CYYW CYND CYAT CYOW CYLA CYPO CYBG CYWA CYTL CYPQ CYBN CYPL CYLD CYQB CYCK CYRL CYMT CYRJ CYHD CYUY CYXR CZSJ CZEM CYSK CYER CYZR CYGQ CYAM CYZE CYKL CYHM CYSC CYPH CYXL CYYU CYSN CYQK CYSB CYGK CYTQ CYKF CYTJ CYVP CYQT CYGW CYTS CYGL CYTZ CYAD CYKZ CYAH CYYZ CYLH CYOO CYXU CYTR CYSP CYRQ CYNM CYMU CYMX CYVO CYUL CYOY CYHU CWQG CYMO CYKQ CYQA CYXZ CZMD CYNC CYHH CYVV CYYB CYQG CYKP),
    pacific:             ~w(CYXX CYCD CBBC CYYF CYBD CYZT CYCP CYPW CYBL CYXS CYCG CYPR CYCQ CYDC CWCL CYQZ CYIN CYRV CYQQ CYZP CYXC CYYD CYDQ CWSW CWDL CYSW CYDL CZST CYYE CYXT CYXJ CYAZ CYGE CYVR CYHE CYWH CYKA CYYJ CYLW CAW4 CWLY CBE9 CYZY CWAE CZMT CYWL CWWQ),
    prairies:            ~w(CYBV CYLL CYBR CYYL CYVT CYLJ CYYC CYXH CYBW CYMJ CYYQ CYBU CYOD CYQW CYDN CYNE CYEG CYPE CYED CZPC CZVL CYPG CYET CWIQ CYEN CYPA CYFO CYQF CYPY CYQR CYMM CYXE CYGX CYZH CYQU CYSF CYOJ CYYN CYIV CYBQ CWHN CYQD CYKJ CYTH CYKY CYZU CYVC CYWG CYQL CYQV),
    nunavut:             ~w(CYKO CYIK CYEK CYKG CYBK CYAS CWOB CYLC CWVD CYBB CWRF CWLX CYTE CYUT CWFD CYXP CWUP CYPX CWYM CYVM CYCS CYHA CYCY CYRT CYZS CWRH CWUW CWRX CYHK CYZG CYUX CYUS CYGT CYYH CYFB CYXN),
    yukon_and_northwest: ~w(CYKD CWKP CYXQ CWKM CYDB CYCO CYCB CYUJ CZCP CWLI CWPX CYLK CYVL CYMA CWXR CYVQ CYDA CYOC CWON CYPC CYWJ CYSY CYOA CYUA CZFA CWVH CYGH CYZW CYJF CYUB CZFM CZFN CYFR CYHI CYFS CYQH CYSM CYWE CYRA CYXY CWIL CYWY CYHY CYZF CYEV)
  }

  def names do
    Map.keys(@regions)
  end

  def stations_for(region) do
    Map.get(@regions, region)
  end
end