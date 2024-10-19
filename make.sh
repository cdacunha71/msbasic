if [ ! -d tmp ]; then
	mkdir tmp
fi

for i in eater; do

echo $i
ca65 -D $i msbasic.s -o tmp/$i.o &&
cp tmp/$i.bin tmp/$i.bin.$(date +%y%m%d_%H%M)
ld65 -C $i.cfg tmp/$i.o -o tmp/$i.bin -Ln tmp/$i.lbl

done

