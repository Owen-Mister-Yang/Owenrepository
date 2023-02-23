#!/bin/bash
top_path=`pwd`
mp_branch=$1
ver=$2
repo list |tee repolist.txt #获取所有的git库本地path和远程path输出到文件

cat repolist.txt |awk -F " : " '{print $2}' |tee remote.txt #过滤repolist.txt文件的第二列以:隔开并输出到 remote.txt文件

rm -f ${top_path}/push.txt  #删除最终push到Gerrit的push.txt文件
cat remote.txt |while read line #以remote.txt循环每行，line为变量（每行）
do
dir=`cat .repo/manifest.xml |grep "\"${line}\"" |awk -F 'path="' '{print $2}' |awk -F '" revision=' '{print $1}'`  #定义一个变量dir最终获取本地git库的目录路径
branch=`cat .repo/manifest.xml |grep "\"${line}\"" |awk -F ' upstream="' '{print $2}' |awk -F '"' '{print $1}'`  #定义一个变量branch最終获取manifest.xml里的upstream上游分支名
if [ -z $dir ]; then #如果git库目录不存在（为空时）
    dir=$line    #dir=远程仓库路径
fi
echo "${dir} : ${branch}" >> ${top_path}/push.txt   #把git库本地路径 和上游分支名 重定向到当前路径下push.txt文件里
done

sed -i s/TCTROM-S-MTK-V5.0-dev-Gcs/TCTROM-S-MSSI-MP-${ver}.0-gcs/g push.txt    		#将分支TCTROM-S-MTK-V5.0-dev-Gcs替换替换为TCTROM—S-MSSI-MP-${ver}.0.gcs    ${ver}为第二个位置参数  	 	$2    1180
sed -i s/TCTROM-S-TARGET-V5.0-dev-Gcs/TCTROM-S-TARGET-MP-${ver}.0-gcs/g push.txt    #将分支TCTROM-S-TARGET-V5.0-dev-Gcs替换为TCTROM-S-TARGET-MP-${ver}.0-gcs   ${ver}为第二个位置参数		$2    8
sed -i s/mt6833-s0-v1.0-dint-gcs/${mp_branch}/g push.txt 						    #将主分支mt6833-s0-v1.0-dint-gcs替换为${mp_branch}                         ${mp_branch}第一个位置参数 	$1    593
sed -i s/TCTROM-S-V5.0-dev-Gcs/TCTROM-S-MP-${ver}.0-gcs/g push.txt                  #将分支TCTROM-S-V5.0-dev-Gcs替换为TCTROM-S-MP-${ver}.0-gcs      		   ${ver}为第二个位置参数   	$2    21     TCTROM-S-MTK-V5.0-dev-Gcs.xml

cat push.txt |grep -v "${ver}" |grep -v "${mp_branch}" | tee sed.txt    # 过滤push.txt 还有哪些没有替换的 将结果输出到sed.txt             

cat sed.txt | while read line # 将sed.txt中的每一行进行循环以line为变量
do
aaa=`printf "$line" |awk -F ' : ' '{print $2}'`   #aaa作为变量接收每一行的第二列

sed -i "s/${aaa}/${mp_branch}/g" push.txt    #将第二列的值替换为量产分支（target）       可以参考分支图：https://confluence.tclking.com/pages/editpage.action?pageId=108010572
done

cat push.txt | while read line #替换检查完毕以后循环push.txt 
do
dir=`printf "${line}" |awk -F " : " '{print $1}'`    #dir作为变量获取每一行的第一列git库本地目录 
branch=`printf "${line}" |awk -F " : " '{print $2}'` #branch作为变量获取每一行的第二列上游分支
echo dir:$dir 
echo br:$branch
cd ${top_path}/${dir}  #cd 到git本地库
git push origin HEAD:${branch}   #$push 到远程仓库 ###{branch}指定上游分支
if [ $? -eq 0 ]; then  #如果git push成功
    echo "push done"  
else
    echo $line >> $top_path/push_failed_project_name.log   #git push失败的行输出到当前路径下的push_failed_project_name.log
fi
done
      
