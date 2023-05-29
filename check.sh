#!/bin/bash


id=$1

echo "Report on stderr/stdout"

n_all=`ls hq-$id-*.stderr | wc -l`
n_miss=`grep -m 1 'is not TRUE' hq-$id-*.stderr | wc -l`

echo "Calculations initiated:           " $n_all
echo "  - Input files missing:          " $n_miss

echo "Input files in total:             " `ls data/input/locations/input_*.txt | wc -l`
echo "Calculations started with input:  " $(($n_all - $n_miss))
echo "  - Colony died:                  " `grep -m 1 'Colony died' hq-$id-*.stdout | wc -l`
echo "  - Division by zero:             " `grep -m 1 'Division by zero' hq-$id-*.stderr | wc -l`
echo "  - OutOfMemoryError:             " `grep -m 1 'OutOfMemoryError' hq-$id-*.stderr | wc -l`

echo
echo "Report on output files"

n_corrupted=0
n_divzero=0
n_died=0
n_other=0
for f in data/output/*.csv; do
    n_lines=`cat $f | wc -l`
    if [[ "$n_lines" != "1097" ]]; then
        n_corrupted=$((n_corrupted+1))
        continue
    fi
    divzero=`grep -m 1 RuntimePrimitiveException $f`
    if [[ "$divzero" != "" ]]; then
        n_divzero=$((n_divzero+1))
        continue
    fi
    n_bees=`tail -n 1 $f | cut -d ',' -f9`
    if [[ "$n_bees" == "0" ]]; then
        n_died=$((n_died+1))
        continue
    fi
    n_other=$((n_other+1))
done

echo "Output files:                     " `ls data/output | wc -l`
echo "  - Output corrupted:             " $n_corrupted
echo "  - Colony died:                  " $n_died
echo "  - Division by zero:             " $n_divzero
echo "  - Other (OK):                   " $n_other
#echo "  - Division by zero:      " `grep -m 1 RuntimePrimitiveException data/output/*.csv | wc -l`
