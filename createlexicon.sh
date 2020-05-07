#!/bin/bash

if [ $# -ne 4 ]; then
    echo "Usage $0 <vocab> <ref_lex> <lang EN/HI> <output_folder>"
    exit 1
fi

echo "preparing lexicon"

vocab=$1
ref_lex=$2
langid=`echo $3 | tr 'a-z' 'A-Z'`
odir=$4

id=`echo $vocab | sed 's:.vocab::'`

if [ "$langid" == "EN" ]; then
  python scripts/make_lexicon.py $vocab $ref_lex >${id}.lexicon 2>${id}_missingwords.lexicon || exit 1
  python scripts/make_lexicon.py ${id}_missingwords.lexicon >>${id}.lexicon 2>${id}_missingwords2.lexicon || exit 1
  cat ${id}_missingwords2.lexicon | tr 'a-z' 'A-Z' > ${id}_missingwords.lexicon || exit 1

  g2p.py --model conf/model-b.key --apply ${id}_missingwords.lexicon >${id}.lexicon_g2p 2>${id}_missingwords2.lexicon || exit 1
  awk -F"\t" '{$1=tolower($1); print$1"\t"$2}' ${id}.lexicon_g2p >> ${id}.lexicon || exit 1

elif [ "$langid" == "HI" ]; then
  python scripts/make_lexicon.py $vocab $ref_lex >${id}.lexicon 2>${id}_missingwords.lexicon || exit 1
  grep "[a-zA-Z,.:]" ${id}_missingwords.lexicon > $odir/english_words.txt 
  grep -v "[a-zA-Z0-9,.:]" ${id}_missingwords.lexicon > $odir/hindi_words.txt
  grep "[0-9]" ${id}_missingwords.lexicon > $odir/numbers.txt
  scripts/get_prons.sh hi $ref_lex $odir/hindi_words.txt >> ${id}.lexicon || exit 1
  python scripts/make_lexicon.py $odir/english_words.txt $ref_lex >>${id}.lexicon 2>${id}_missingwords.lexicon || exit 1
  python scripts/make_lexicon.py ${id}_missingwords.lexicon >>${id}.lexicon 2>${id}_missingwords2.lexicon || exit 1
  cat ${id}_missingwords2.lexicon | tr 'a-z' 'A-Z' > ${id}_missingwords.lexicon || exit 1
  g2p.py --model conf/model-b.key --apply ${id}_missingwords.lexicon >${id}.lexicon_g2p 2>${id}_missingwords2.lexicon || exit 1
  awk -F"\t" '{$1=tolower($1); print$1"\t"$2}' ${id}.lexicon_g2p >> ${id}.lexicon || exit 1

  python scripts/get_number_prons.py $odir/numbers.txt $ref_lex >> ${id}.lexicon || exit 1
fi

rm ${id}.lexicon_g2p || exit 1
mv ${id}_missingwords2.lexicon ${id}_missingwords.lexicon || exit 1
python dataCleanup/clean_lexicon.py ${id}.lexicon | sort -u > temp || exit 1
mv temp ${id}.lexicon || exit 1

