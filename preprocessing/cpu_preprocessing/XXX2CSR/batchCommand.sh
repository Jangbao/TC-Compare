#https://snap.stanford.edu/data/
g++ SNAP2CSR.cpp -o SNAP2CSR

#snap twitter7
#https://github.com/ANLAB-KAIST/traces/releases/tag/twitter_rv.net
g++ MTX2CSR.cpp -o MTX2CSR


# ./SNAP2CSR ../../../data/snap_dataset/As-Caida/as-caida20071105.txt        ../../../data/csr_dataset/As-Caida/      
# ./SNAP2CSR ../../../data/snap_dataset/P2p-Gnutella31/p2p-Gnutella31.txt        ../../../data/csr_dataset/P2p-Gnutella31/
# ./SNAP2CSR ../../../data/snap_dataset/Email-EuAll/email-EuAll.txt        ../../../data/csr_dataset/Email-EuAll/
# ./SNAP2CSR ../../../data/snap_dataset/Soc-Slashdot0922/soc-Slashdot0902.txt     ../../../data/csr_dataset/Soc-Slashdot0922/
# ./SNAP2CSR ../../../data/snap_dataset/Web-NotreDame/web-NotreDame.txt     ../../../data/csr_dataset/Web-NotreDame/
# ./SNAP2CSR ../../../data/snap_dataset/Com-Dblp/com-dblp.ungraph.txt    ../../../data/csr_dataset/Com-Dblp/
# ./SNAP2CSR ../../../data/snap_dataset/Amazon0601/amazon0601.txt     ../../../data/csr_dataset/Amazon0601/
# ./SNAP2CSR ../../../data/snap_dataset/RoadNet-CA/roadNet-CA.txt     ../../../data/csr_dataset/RoadNet-CA/
# ./SNAP2CSR ../../../data/snap_dataset/Wiki-Talk/wiki-Talk.txt     ../../../data/csr_dataset/Wiki-Talk/
# ./SNAP2CSR ../../../data/snap_dataset/Web-BerkStan/web-BerkStan.txt     ../../../data/csr_dataset/Web-BerkStan/
# ./SNAP2CSR ../../../data/snap_dataset/As-Skitter/as-skitter.txt     ../../../data/csr_dataset/As-Skitter/
# ./SNAP2CSR ../../../data/snap_dataset/Cit-Patents/cit-Patents.txt     ../../../data/csr_dataset/Cit-Patents/
# ./SNAP2CSR ../../../data/snap_dataset/Soc-Pokec/soc-pokec-relationships.txt    ../../../data/csr_dataset/Soc-Pokec/
# ./SNAP2CSR ../../../data/snap_dataset/Sx-Stackoverflow/sx-stackoverflow.txt    ../../../data/csr_dataset/Sx-Stackoverflow/
# ./SNAP2CSR ../../../data/snap_dataset/Com-Lj/com-lj.ungraph.txt    ../../../data/csr_dataset/Com-Lj/
# ./SNAP2CSR ../../../data/snap_dataset/Soc-LiveJ/soc-LiveJournal1.txt    ../../../data/csr_dataset/Soc-LiveJ/
# ./SNAP2CSR ../../../data/snap_dataset/Com-Orkut/com-orkut.ungraph.txt    ../../../data/csr_dataset/Com-Orkut/
# ./MTX2CSR ../../../data/snap_dataset/Twitter7/twitter7/twitter7.mtx                ../../../data/csr_dataset/Twitter7/
# ./SNAP2CSR ../../../data/snap_dataset/Com-Friendster/com-friendster.ungraph.txt   ../../../data/csr_dataset/Com-Friendster/
