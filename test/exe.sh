#创建输入输出文件夹
rm Path.txt
rm Token.txt
rm TakenSum.txt
rm PathSum.txt
rm sample4-out.txt
rm -rf inp
rm -rf out
mkdir inp
mkdir out
touch Path.txt
touch Token.txt
touch TakenSum.txt
touch PathSum.txt
touch sample4-out.txt
#设置种子
echo "lllllll" >> ./inp/seed1
#执行脚本
/data/SymCC/test/test2.sh -i ./inp -o out ./sample