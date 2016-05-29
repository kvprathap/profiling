#!/bin/bash
#echo $$
IN_DIR=$1
OUT_DIR=$2
for f in $IN_DIR/*.exe
do
    echo Processing $f
    out=$(basename $f | cut -f 1 -d '.')
    #exe="${@:2}"
    #echo $exe
    echo $out
    OUTDIR=$OUT_DIR/$out
    SUM=0
    valgrind  --trace-symtab=yes --log-file=${out}-raw --tool=lackey --trace-mem=yes $f -autogo > log-${out} &
    pid=$!
    #echo $pid
    WAIT=0
    while [ $WAIT == 0 ]
    do
        WAIT=$(grep  -i "START" log-${out} | wc -l)
    done
    cat /proc/$pid/maps > maps-${out}.txt
    wait $pid
    printf "%s\t%s\t%s\n" "#ofAccesses" "PageFrameNumber" "Hotness"> ${out}-Page
    printf "%s\t%s\t%s\t%s\n" "#ofAccesses" "Address" "Hotness" "symbol"> ${out}-Addr
    # Find the hot pages
    awk  '{if ($1 == "L" || $1 == "S") { print $2}}'  ${out}-raw | awk -F, '{print $1}' | awk '{print substr($1,0,length($0)-3)}' > ${out}-inter0
    awk  '{if ($1 == "L" || $1 == "S") { print $2}}'  ${out}-raw | awk -F, '{print $1}' > ${out}-address0
    sort  ${out}-inter0 | uniq -c | sort -nr >  ${out}-inter1
    sort  ${out}-address0 | uniq -c | sort -nr >  ${out}-address1
    SUM=$(awk '{print $1}' "${out}-inter1" | awk '{tot+=$1} END {print tot}')
    #echo $SUM
    #awk 'BEGIN{print "'$SUM'" }'
    awk '{print $1,$2,$1/"'$SUM'" * 100}'  ${out}-inter1 >> ${out}-Page
    SUM=$(awk '{print $1}' "${out}-address1" | awk '{tot+=$1} END {print tot}')
    awk '{print $1,$2,$1/"'$SUM'" * 100}'  ${out}-address1 >> ${out}-Addr
    rm -rf ${out}-inter*
    rm -rf ${out}-addre*
    column -t $out-Page > ${out}-page.txt
    column -t ${out}-Addr > ${out}-location
    rm -rf ${out}-Page
    rm -rf ${out}-Addr
    objdump -S $f > ${out}-objdump.txt
    sed -e '/I /,$d' ${out}-raw > ${out}-symbols-raw
    # Extracting Symbol information
    awk  'NR==FNR{a[NR]=$1;b[NR]=$2;c[NR]=$3;next} {for (i in b) if ($0 ~ b[i]) {if ($12) print a[i]"\t"b[i]"\t"c[i]"\t"$12;break;}fflush()}' ${out}-location ${out}-symbols-raw > $out-inter0
    awk 'NR==FNR{a[$2]=1;next}!a[$2]' $out-inter0 ${out}-location > $out-inter1
    cat $out-inter1 >> $out-inter0
    sort -s -nr -k 1,1 $out-inter0 | column -t > $out-inter2
    sed '1h;1d;$!H;$!d;G' $out-inter2 > $out-address-symbols.txt
    rm -rf ${out}-inter*
    rm -rf ${out}-symbols-raw
    rm -rf ${out}-raw
    rm -rf ${out}-location
    mkdir -p $OUTDIR
    mv $out-address-symbols.txt $OUTDIR/
    mv $out-page.txt $OUTDIR/
    mv $out-objdump.txt $OUTDIR/
    mv maps-${out}.txt  $OUTDIR/
    mv log-${out} $OUTDIR/
done
#valgrind --tool=massif --stacks=yes --time-unit=i ./cacheb01.exe -autogo
