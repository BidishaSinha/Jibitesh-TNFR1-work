nr = roiManager("count");

for (i=0;i<nr;i++) {
	roiManager("select", i);
	run("Enlarge...", "enlarge=2");
	roiManager("add");
}
delArray = newArray(0);
for (i=0;i<nr;i++) {
	donut = newArray(i,i+nr);
	delArray = Array.concat(delArray,i+nr);
	roiManager("select", donut);
	roiManager("XOR");
	roiManager("add");
}
roiManager("select", delArray);
roiManager("delete");
