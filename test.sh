#!/bin/bash

set -u
# set -x # DEBUG

## install dependencies and use development version of hts_shrink
# pip3 install rdkit
# opam install --fake conf-rdkit
# opam install get_line pardi molenc
# git clone https://github.com/UnixJunkie/hts_shrink.git
# cd hts_shrink
# opam pin add hts_shrink .

# erase previous run
rm -f data/pcid_435034_act_dec_std_rand.AP \
      data/pcid_435034_act_dec_std_rand.idx \
      data/pcid_435034_act_dec_std_rand.mol2 \
      data/pcid_435034_act_dec_std_rand.smi \
      data/test.AP \
      data/test.AP.dbbad \
      data/train.AP \
      data/train.AP.dbbad \
      scan.log

# extract test data
xz --keep --decompress data/pcid_435034_act_dec_std_rand.smi.xz
NB_LINES=`wc -l data/pcid_435034_act_dec_std_rand.smi | awk '{print $1}'`
HALF=$(($NB_LINES/2))
HALF_PLUS_ONE=$((1 + $NB_LINES/2))

# encode molecules
molenc.sh -n `getconf _NPROCESSORS_ONLN` --no-std \
          -i data/pcid_435034_act_dec_std_rand.smi \
          -o data/pcid_435034_act_dec_std_rand.AP

# randomize dataset
head -1 data/pcid_435034_act_dec_std_rand.AP > data/rand.AP
get_line -r 2..$HALF_PLUS_ONE \
         -i data/pcid_435034_act_dec_std_rand.AP --rand >> data/rand.AP

# create training set
head -$HALF_PLUS_ONE data/rand.AP > data/train.AP

# create test set
head -1 data/rand.AP > data/test.AP # header line
tail -$HALF data/rand.AP >> data/test.AP

# run DBBAD
hts_shrink_dbbad --train data/train.AP --test data/test.AP \
                 --dscan scan.log

# REMARKS:
# - ECFP2:      A_train: 197 D_train: 30680 AD_A_test: 197 AD_D_test: 6520 old: 0.006380 new: 0.029329 EF: 4.597
# - atom pairs: A_train: 197 D_train: 30680 AD_A_test: 197 AD_D_test: 9884 old: 0.006380 new: 0.019542 EF: 3.063
