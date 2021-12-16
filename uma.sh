#!/bin/bash
LANG="ja_JP.UTF-8"
DIST_FLAG=0
BASE_POINT="${PWD}"
#cdしたあと絶対パスでもとに戻れるようにします。
DISTRIBUTION="$(cat /etc/os-release | grep "^NAME=" |awk -F '=' '{gsub(/"/,"",$2);printf $2"\n"}')"
if [[ "${DISTRIBUTION}" == *buntu ]]; then
	echo "環境:${DISTRIBUTION}"
elif [[ "${DISTRIBUTION}" == MSYS2 ]]; then
	echo "環境:${DISTRIBUTION}"
	echo "MSYS2で実行されているようですが、winptyから起動されてない場合はfzfが動かないのでうまく動かなかった場合winptyから起動されてないもんだと思ってください。"
	fi
else
	echo "環境:${DISTRIBUTION}"
	echo "想定していない環境です。"
	echo "vgmstreamなどの必要なコマンドは手動でインストールして下さい。"
	DIST_FLAG=2
fi
if [[ ! $(basename "${PWD}") == umamusume ]]; then echo "umamusumeフォルダーで実行してくれ";echo "/mnt/c/Users/ユーザ名/AppData/LocalLow/Cygames/umamusume";echo "が一般的だと思います。";exit 1;fi
if [[ -z meta ]]; then echo "mata ファイルがあるところで実行してくれ。";echo "/mnt/c/Users/ユーザ名/AppData/LocalLow/Cygames/umamusume";echo "が一般的だと思います。";echo "もしくは一度も起動していないためにmetaファイルがないという可能性もあります。";exit 1;fi
export PATH="${HOME}/tmp_com/bin:${HOME}/commands/bin:${PATH}"
#このスクリプトでvgmstreamをインストールするとここにインストールされるのでPATHを通します。
yes_or_no(){
	read -e -n1 -p "よろしいですか?[Y/n]:" YN
	case ${YN} in
	Y|y|''|' ')
		INSTALL_FLAG=1;;
	N|n)
		echo "インストールしません。"
		INSTALL_FLAG=0;;
	*)
		echo "予期せぬ文字が入力されたのでインストールしません。"
		INSTALL_FLAG=0;;
	esac
}
###vgmstreamのインストールは不安定なので公式からバイナリをダウンロードすることにしました。
###一応古いソースから自分でビルドしたい人向けに残しておきます。
<<COMMENTOUT
install_vgmstream(){
	#~/ で組み立てることでWSL2ならWSLのコンテナ内なのでウイルス対策ソフトの影響を受けずに組み立てられると思いこのような形にしました。
	echo "tmp_comにvgmstreamをビルドしてインストールします。"
	FLAG=1
	yes_or_no
	if [[ ! ${INSTALL_FLAG} == 1 ]]; then return 1;fi
	IWILLBEBACK="${PWD}"
	mkdir -p ${HOME}/tmp_com/bin
	sudo apt update 
	sudo apt upgrade -y
	sudo apt install gcc g++ cmake make autoconf automake libtool git \
			libmpg123-dev libvorbis-dev libspeex-dev \
			audacious-dev audacious libglib2.0-dev libgtk2.0-dev libpango1.0-dev \
			libao-dev liblz4-tool sqlite3 perl pkg-config -y
	pkg-config --modversion audacious
	git clone https://github.com/losnoco/vgmstream ~/vgmstream &&\
	cd ~/vgmstream &&\
	mkdir -p build && cd build &&\
	cmake -DCMAKE_INSTALL_PREFIX=~/tmp_com ../ &&\
	make -j20 &&\
	sudo make install
	SUCCESS=$?
	cd ../../
	rm -rf vgmstream
	cd "${IWILLBEBACK}"
	if [[ ! ${SUCCESS} == 0 ]]; then echo "インストールに失敗している可能性があります。";fi
}
COMMENTOUT
###
if [[ "${DIST_FLAG}" == 0 ]]; then
	install_vgmstream(){
		##インストールばしょを「~/commands/bin」にすることにしました。
		##いらんかったら消してくれって意味でいままで「~/tmp_com」って名前にしてたんだけどよくわからんしな。
		##ただ、どっちにあっても大丈夫なようにはしておくので、バイナリの配置場所をいまから変える必要はないです。
		echo "~/commands/binにvgmstreamをビルドしてインストールします。"
		FLAG=1
		yes_or_no
		if [[ ! ${INSTALL_FLAG} == 1 ]]; then return 1;fi
		sudo apt update 
		sudo apt upgrade -y
		sudo apt install tar git sqlite3
		mkdir -p ~/commands/bin
		wget $(curl https://vgmstream.org/downloads | tr '"' '\n' | grep 'linux/vgmstream-cli.tar.gz')
		tar -xvf vgmstream-cli.tar.gz -C ~/commands/bin
		rm vgmstream-cli.tar.gz
	}
	install_sqlite(){
		echo "apt でsqlite3をインストールします。"
		FLAG=1
		yes_or_no
		if [[ ! ${INSTALL_FLAG} == 1 ]]; then return 1;fi
		sudo apt update &&\
		sudo apt upgrade -y &&\
		sudo apt install sqlite3 perl git -y
	}
elif [[ "${DIST_FLAG}" == 1 ]]; then
	install_vgmstream(){
		echo "~/commands/binにvgmstreamをビルドしてインストールします。"
		FLAG=1
		yes_or_no
		if [[ ! ${INSTALL_FLAG} == 1 ]]; then return 1;fi
		mkdir -p ~/commands/bin
		mkdir -p ~/tmp_vg_install
		echo $(curl https://vgmstream.org/downloads | tr '"' '\n' | grep 'windows/vgmstream-win.zip')
		wget -P ~/tmp_vg_install $(curl https://vgmstream.org/downloads | tr '"' '\n' | grep 'windows/vgmstream-win.zip') 
		unzip ~/tmp_vg_install/vgmstream-win.zip -d ~/tmp_vg_install
		mv ~/tmp_vg_install/test.exe ~/tmp_vg_install/vgmstream-cli.exe
		mv ~/tmp_vg_install/*.dll ~/tmp_vg_install/*.exe ~/commands/bin
		rm -rf ~/tmp_vg_install
	}
	install_sqlite(){
		echo "pacman でsqlite3をインストールします。"
		FLAG=1
		yes_or_no
		if [[ ! ${INSTALL_FLAG} == 1 ]]; then return 1;fi
		pacman -Syy
		pacman -S mingw-w64-ucrt-x86_64-sqlite3 git
		pacman -Su
	}
else
	install_vgmstream(){
		echo "vgmstream-cliコマンドがないようなのでインストールしてください。"
		echo "バイナリの名前が「vgmstream-cli」でないとインストールされてないことになってしまうので違う名前の場合はシンボリックリンクを貼るかリネームして下さい。"
		FLAG=1
	}
	install_sqlite(){
		echo "sqlite3コマンドがないようなのでインストールしてください。"
		echo "バイナリの名前が「sqlite3」でないとインストールされてないことになってしまうので違う名前の場合はシンボリックリンクを貼るかリネームして下さい。"
		FLAG=1
	}
fi
install_fzf(){
	echo "githubからfzfをインストールします。"
	FLAG=1
	yes_or_no
	if [[ ! ${INSTALL_FLAG} == 1 ]]; then return 1;fi
	rm -rf ~/.fzf
	git clone --depth 1 https://github.com/junegunn/fzf.git ~/.fzf && \
	yes | ~/.fzf/install
}

if [[ $(type vgmstream-cli 2>/dev/null) ]];then 
	VGMSTREAM="vgmstream-cli"
elif [[ $(type vgmstream_cli 2>/dev/null) ]]; then
	VGMSTREAM="vgmstream_cli"
else
	echo "vgmstream-cliコマンドがないようです。"
	install_vgmstream
fi
	

if [[ ! $(type fzf) ]];then echo "fzfコマンドがないようです。";install_fzf;fi
if [[ ! $(type sqlite3) ]];then echo "sqlite3コマンドがないようです。";install_sqlite;fi

if [[ ${FLAG} == 1 ]]; then echo "環境のセットアップが済んでいましたら、もう一度スクリプトを実行し直してください。";exit 0;fi
#ここまで環境の確認と足りないもののインストール。

###############
###ここから本体###
###############
PREFIX="解析"
COPYFLAG=0
PARALLEL=1
if [[ -n "${TERM}" ]]; then SCREEN_WIDTH=$(tput cols); else SCREEN_WIDTH=20;fi

ASSET_TYPE="_3d_cutt announce atlas bg chara gacha gachaselect guide home imageeffect item lipsync live loginbonus minigame mob outgame paddock race single story storyevent supportcard transferevent uianimation"
#アセットの種類を選択するときに使います。

while getopts "cfj:prUh" OPT;do
	case $OPT in
		"c" ) COPYFLAG=1;;
		"f" ) COPYFLAG=2;;
		"j" ) PARALLEL=${OPTARG}
			if [[ "$PARALLEL" =~ ^[0-9]+$ ]]; then
				if [[ ${PARALLEL} -le 20 && ${PARALLEL} -ge 1 ]]; then
					echo "コピーの並列処理数を${PARALLEL}に設定しました。"
				else
					PARALLEL=1
					echo "並列処理数は20以下1以上で入力してください。"
					echo "よって1に再設定されました。"
					read -e -n1 -p "わかりましたら何かキーを押してください。"
				fi
			else
				echo "数値を入力してください。"
				echo "よって1に再設定されました。"
				read -e -n1 -p "わかりましたら何かキーを押してください。"
			fi
			;;
		"p" ) read -e -p "任意の出力先のフォルダー名を入力してください。:" PREFIX
			if [[ ${PREFIX} == '' || ${PREFIX} == "* *" ]];then PREFIX="解析/";fi
			echo "出力先を${PREFIX}とします。"
			#空白や何も入力されてないとルートに書き込もうとする可能性があるので回避しておきます。
			#スペースもエラーの元なのでスペースが入っている場合もデフォルトに戻します。
			;;
		"U" ) if [[ ! -d script_uma ]]; then git clone --depth 1 https://github.com/incompetence33/uma_sh.git script_uma;fi
			cd script_uma && git pull && cd "${BASE_POINT}"
			if [[ ! -L uma.sh ]]; then rm -f uma.sh;ln -s script_uma/uma.sh;fi
			exit 0
			;;
		* )
			echo "-c :"
			echo "	コピーするときにサイズを比較して等しい場合スキップします。"
			echo "-f :"
			echo "	コピーするとき全てのファイルをコピーします。"
			echo "-j :"
			echo "	./uma.sh -j2"
			echo "	./uma.sh -j 2"
			echo "	このようにすることでコピーするときの並列処理数を20以下1以上の整数で設定できます。"
			echo "	あんまり数を増やすとパソコンが壊れないか心配なので上限を設けました。"
			echo "	20を超える数や数値以外が入力された場合1に設定し直されます。"
			echo "	いまのところコピーされた数などが正常に表示できないことを、ご了承ください。"
			echo "-p :"
			echo "	出力先のフォルダ名を変更できます(非推奨)。"
			echo "	ただしスペースを名前に含めることはできません。"
			echo "-U :"
			echo "	スクリプトをアップデートします。"
			echo "	このオプションを初めて実行する場合ならumamusumeフォルダーにgit cloneされます。"
			echo "	そうでない場合はgit pullするだけです。"
			echo "	シンボリックリンクを作成するのですでにumamusumeフォルダーにuma.shというファイルがある場合削除しておいて下さい。"
			echo "-h :"
			echo "	ヘルプを表示します。" 
			exit 0;
	esac
done

case ${COPYFLAG} in
	"0" )
		#通常。
		dircp (){
			#cpするときに足りないディレクトリを勝手に作ってくれます。
			if [[ "${2}" == */* ]]; then
				if [[ ! -d "${2/\/$(basename "${2}")}" ]]; then
					mkdir -p "${2/\/$(basename "${2}")}"
				fi
			fi
			#コピー元の存在チェック。
			if [[ ! -e "${1}" ]]; then
				echo "ファイルがありません: ${1} (${2})"
				((NOT_FOUND++))
				return 2
			fi
			#既にコピー先があったらスキップ。
			if [[ -e "${2}" ]]; then
				echo "スキップ: ${2}"
				((SKIIPED_FILE++))
				return 1
			else
				cp -r "${1}" "${2}"
				((COPYED_FILE++))
				return 0
			fi
		};;
	"1" )
		#サイズでコピーするかを判断する。
		dircp (){
			#cpするときに足りないディレクトリを勝手に作ってくれます。
			if [[ "${2}" == */* ]]; then
				if [[ ! -d "${2/\/$(basename "${2}")}" ]]; then
					mkdir -p "${2/\/$(basename "${2}")}"
				fi
			fi
			# コピー元の存在チェック
			if [[ ! -e "${1}" ]]; then
				#echo "ファイルがありません: ${1} (${2})"
				((NOT_FOUND++))
				return 2
			fi
			# コピー先とサイズが同じならスキップ。
			if [[ $(wc -c < ${1}) == $(wc -c < ${2}) ]]; then
				#echo "スキップ: ${2}"
				((SKIIPED_FILE++))
				return 1
			else
				echo "${1} → ${2}"
				cp -r "${1}" "${2}"
				((COPYED_FILE++))
				return 0
			fi
		};;
	"2" )
		#全てコピーする。
		dircp (){
			#cpするときに足りないディレクトリを勝手に作ってくれます。
			if [[ "${2}" == */* ]]; then
				if [[ ! -d "${2/\/$(basename "${2}")}" ]]; then
					mkdir -p "${2/\/$(basename "${2}")}"
				fi
			fi
				cp -r "${1}" "${2}" > /dev/null 2>&1
				((COPYED_FILE++))
		};;
	* )
		echo "異常なフラグです。終了します。"
		exit 1;
esac
#dirpdf内で分岐してもよかったけど毎回ifやcaseすると時間がかかるかな？と思ってこのような形にしました。

copy_files (){
	MAX="$(cat list.txt | wc -l)"
	PROGRESS=1
	SKIIPED_FILE=0
	COPYED_FILE=0
	NOT_FOUND=0
	echo "目的のファイルをコピーしています……"
	echo -ne "進度: (${PROGRESS}/${MAX} (コピーされた数: ${COPYED_FILE} スキップ数: ${SKIIPED_FILE} 存在なし: ${NOT_FOUND}))\c"
	echo -ne "\r\c"
	while [[ ${MAX} -ge ${PROGRESS} ]]; do
		for C_JOB in $(seq 2 $((PARALLEL)));do
			dircp $(cat list.txt | awk -F '[ ]' 'NR=='${PROGRESS}+${C_JOB}-1'{printf "'${1}' '"${PREFIX}"''${2}'\n" ,'${3}}'') &\
		done
		dircp $(cat list.txt | awk -F '[ ]' 'NR=='${PROGRESS}'{printf "'${1}' '"${PREFIX}"''${2}'\n" ,'${3}}'')
		#${PROGRESS}行目から、要素1(ハッシュファイル名)、要素(元の名前と場所)を取得してコピーします。
		echo -ne "進度: (${PROGRESS}/${MAX} (コピーされた数: ${COPYED_FILE} スキップ数: ${SKIIPED_FILE} 存在なし: ${NOT_FOUND}))\c"
		echo -ne "\r\c"
		((PROGRESS +=${PARALLEL}))
	done
	echo "進度: ($((PROGRESS-1))/${MAX} (コピーされた数: ${COPYED_FILE} スキップ数: ${SKIIPED_FILE} 存在なし: ${NOT_FOUND}))"
	#処理数が実際より1多くなってしまうのでここで減らしています()
}

kyoukaisen(){
	#ウィンドウの横幅分文字を並べてくれます。区切りとして使います。
	#$1を参照して並べる文字を変えることもできます。
	if [[ -n "${TERM}" ]]; then SCREEN_WIDTH=$(tput cols); else SCREEN_WIDTH=20;fi
	LINEWORD="-"
	if [[ -n "$1" ]]; then LINEWORD="$1";fi
	printf -v _hr "%*s" ${SCREEN_WIDTH} && echo ${_hr// /${1-${LINEWORD}}}
}
meta_analyze(){
	#metaを展開します。
	rm -f output_meta_tmp.txt
	echo -ne ".output output_meta_tmp.txt \n.dump a" | sqlite3 meta
	#なんかインデントするとエラーが出てしまうのでechoの拡張で対応した。
	if [[ ${COPYFLAG} == 0 ]]; then 
		if [[ -f output_meta.txt ]]; then 
			if ! $(diff -q output_meta.txt output_meta_tmp.txt > /dev/null 2>&1); then 
				COPYFLAG=1
				echo "metaファイルが更新されているようなので、サイズを比較して差異があった場合コピーするモードで実行します。"
			fi
		fi
	fi
	mv output_meta_tmp.txt output_meta.txt
	sleep 1
}

make_list(){
	#metaを展開したものの中からハッシュファイルと元のファイル名の対応表を作る。
	#TARGETは後に実行する直前に与える。
	#複数スペース区切りで指定できるようにforで回します。
	rm -f list.txt
	for TYPE in ${TARGET};do
		cat output_meta.txt | grep \'${TYPE}\' | awk -F \' '{printf "%s %s '${TYPE}'\n" ,$(NF-3),$(2)}' | sort -u >> list.txt 
	done
	unset TARGET
	#初期化して事故を防ぎます。
}

awbtowav(){
	kyoukaisen "="
	echo "音声を変換します。"
	TARGET="sound"
	#ターゲットを決めます。
	make_list
	#リストを作ります。
	if [[ ${LIVE_ONLY} == 1 ]]; then cat list.txt | grep sound/l/ > tmp_.txt;rm list.txt;mv tmp_.txt list.txt;fi
	#「ライブだけ」が選択されている場合ライブ以外の行はいらないので消します。
	copy_files 'dat/%s/%s' '/%s' 'substr($1,0,2),$1,$2'
	#ファイルをコピーする。パラメータをdircpに渡す。
	#copy_files側は
	#$(cat list.txt | awk -F '[ ]' 'NR=='${PROGRESS}'{printf "'${1}' '"${PREFIX}"''${2}'\n" ,'${3}}'')
	#となっており変数展開後は
	#$(cat list.txt | awk -F '[ ]' 'NR=='${PROGRESS}'{printf "dat/%s/%s '"${PREFIX}"'/%s\n" ,substr($1,0,2),$1,$2}')
	#となります。
	#見にくくなってしまい申し訳ありません。
	kyoukaisen
	echo "wavに変換します。"
	cd ${PREFIX}
	for A in $(find sound -type d | sed -e s/^sound/sound_wav/);do mkdir -p "${A}";done
	#wavだけが入っているディレクトリを作成します。
	kyoukaisen
	echo "awbファイルをwavファイルに変換します。"
	echo "wavファイルは sound_wav/ に出力されます。"
	COUNT=0
	COUNT_TRACK=0
	echo -ne "処理数: ${COUNT} (トラック数:${COUNT_TRACK})\c"
	echo -ne "\r\c"
	
	SKIIPED_FILE=0
	for FILE in $(if [[ ${LIVE_ONLY} == 1 ]]; then find sound/l/ -type f -name "*.awb" ;else find sound/ -type f -name "*.awb";fi);do
		MAXTRACK=$(($(hexdump -s 8 -n 2 -v -e '/1 "%02X "' ${FILE} | awk -F ' ' '{printf "ibase=16; %s%s\n",$2,$1}' | bc)-1))
		#hexdumpで8バイト目から2バイト分を取得してそれを16進から10進にする。
		#その部分はそのawbに何トラック入っているかを表しているため。
		if [[ ! $(ls -1 "$(echo ${FILE/.awb} | sed -e s/^sound/sound_wav/)_"* 2> /dev/null | wc -l) == $((${MAXTRACK}+1)) ]]; then
			#sound_wavに入っているその音声のトラック数とawbの中に入っているトラック数が一致している場合スキップします。
			#差分だけできないか試しましたがうまく出来そうになかったのでやめました。(実況などトラックの後ろに追加されていく形でないものもあるため)
			for TRACK in $(seq -w 0000 ${MAXTRACK});do
				echo -ne "処理数: ${COUNT} (トラック数: ${COUNT_TRACK} スキップ: ${SKIIPED_FILE}) File:$(basename "${FILE}")\c"
				echo -ne "\r\c"
				${VGMSTREAM} -s ${TRACK} -o $(echo ${FILE/.awb} | sed -e s/^sound/sound_wav/)_${TRACK}.wav ${FILE} > /dev/null 2>&1
				((COUNT_TRACK++))
			done
			printf -v _hr "%*s" ${SCREEN_WIDTH} && echo -ne "${_hr// /${1-" "}}\c"
			echo -ne "\r\c"
		else
			((SKIIPED_FILE++))
		fi
		echo -ne "処理数: ${COUNT} (トラック数: ${COUNT_TRACK} スキップ: ${SKIIPED_FILE})\c"
		echo -ne "\r\c"
		((COUNT++))
	done
	echo "処理数: ${COUNT} (トラック数: ${COUNT_TRACK} スキップ: ${SKIIPED_FILE})"
	echo "完了しました。"
	cd "${BASE_POINT}"
	#もとのディレクトリに戻ります。
	kyoukaisen "="
}

asset_rename(){
	kyoukaisen "="
	echo "アセットを仕分けします。"
	make_list
	#ターゲットは先に決められてると思うのでそれに基づいてリストを作ります。
	if [[ ${SORT_MODE} == "単一のディレクトリに入れる" ]]; then cat list.txt | sed -e "s/\ .*\// /g" > tmp_.txt;rm list.txt;mv tmp_.txt list.txt;fi
	#単一のディレクトリに入れる場合先にデータを書き換えてからのほうが楽そうだったので出力先の部分にbasenameみたいな感じの処理をしています。
	#sed -i を使うと私の環境ではすごく遅かったので止めました。
	copy_files 'dat/%s/%s' '/renamed_asset/%s/%s' 'substr($1,0,2),$1,$3,$2'
	kyoukaisen "="
}

masterfile(){
	kyoukaisen "="
	echo "masterファイル"
	mkdir -p ${PREFIX}/masterfile
	echo -ne '.output master.txt\n.dump' | sqlite3 master/master.mdb
	#なんかインデントするとエラーが出てしまうのでechoの拡張で対応した。
	mv master.txt ${PREFIX}/masterfile/
	kyoukaisen "="
}

manifestfiles(){
	kyoukaisen "="
	echo "マニフェストファイル"
	mkdir -p "${PREFIX}"/manifests
	TARGET="manifest manifest2 manifest3"
	make_list
	#目的ファイル名に「/」が入っているので除去します。
	cat list.txt | sed -e "s/\/\///g" > tmp_.txt;rm list.txt;mv tmp_.txt list.txt
	copy_files 'dat/%s/%s' '/manifests/%s' 'substr($1,0,2),$1,$2'
	kyoukaisen "="
}

moviefiles(){
	kyoukaisen "="
	echo "ムービーを整理します。"
	TARGET="movie"
	#ターゲットを決めます。
	make_list
	#リストを作ります。
	copy_files 'dat/%s/%s' '/%s' 'substr($1,0,2),$1,$2'
	echo "移動が完了しました。"
	kyoukaisen "="
}

kyoukaisen "@"
echo "ウマ娘内でデータの一括ダウンロードはしておいてください。"
echo "途中で機能を選択する画面が出てきますので矢印キーとエンターで選んでください。"
kyoukaisen "@"
read -e -n1 -p "よければ何かキーをを押してください。"
mkdir -p "${PREFIX}"
#一応先に出力先ディレクトリを作成しておきます。
TO_DO="$(echo "ライブだけ 音声だけ アセットをまとめるだけ 画像のアセットをリネームして配置 選んだ種類のアセットをリネームして配置 フォントだけ アセットの整理以外 全部 キャラのIDを表示" | tr ' ' '\n' | fzf --reverse --header="実行したいことを選んでください")"
#何をするか決めます。
meta_analyze
masterfile
EXETIMEB="${SECONDS}"
#実行時間を計測します(いらんかもしらんけど)。
case "${TO_DO}" in
	"アセットの整理以外")
		awbtowav
		moviefiles
		manifestfiles
		TARGET="font"
		SORT_MODE="単一のディレクトリに入れる"
		asset_rename;;
	"ライブだけ")
		LIVE_ONLY=1
		awbtowav;;
	"音声だけ")
		awbtowav;;
	"アセットをまとめるだけ")
		TARGET="${ASSET_TYPE}"
		SORT_MODE="単一のディレクトリに入れる"
		asset_rename;;
	"画像のアセットをリネームして配置")
		SORT_MODE="$(echo "単一のディレクトリに入れる ディレクトリも復元する" | tr ' ' '\n' | fzf --reverse --header="モードを選択してください。")"
		TARGET="chara bg supportcard"
		asset_rename;;
	"選んだ種類のアセットをリネームして配置")
		TARGET="$(echo "${ASSET_TYPE}" | tr ' ' '\n' | fzf --reverse --header="アセットの種類を選択してください。")"
		SORT_MODE="$(echo "単一のディレクトリに入れる ディレクトリも復元する" | tr ' ' '\n' | fzf --reverse --header="モードを選択してください。")"
		asset_rename;;
	"フォントだけ")
		TARGET="font"
		SORT_MODE="単一のディレクトリに入れる"
		asset_rename;;
	"全部")
		TARGET="${ASSET_TYPE} font"
		SORT_MODE="単一のディレクトリに入れる"
		asset_rename
		awbtowav
		moviefiles
		manifestfiles;;
	"キャラのIDを表示")
		cat ${PREFIX}/masterfile/master.txt | grep 'text_data VALUES(6,' | awk -F "[,\']" '{printf "%s %s\n" ,$3,$5}' 2>/dev/null;;
	*)
		echo "予期せぬ値が入力されたので終了します。"
		exit 1;;
esac
EXETIMEA="${SECONDS}";EXETIME="$((${EXETIMEA}-${EXETIMEB}))";if [[ ${EXETIME} -ge 3600 ]]; then HOURS="$((${EXETIME}/3600))時間";EXETIME=$((${EXETIME}%3600));fi;if [[ ${EXETIME} -ge 60 ]]; then MINUTES="$((${EXETIME}/60))分";EXETIME=$((${EXETIME}%60));fi;echo "所要時間は ${HOURS}${MINUTES}${EXETIME}秒 でした。"
#実行時間を計算して表示します。
rm -f list.txt
cat ${PREFIX}/masterfile/master.txt | grep 'text_data VALUES(6,' | awk -F "[,\']" '{printf "%s %s\n" ,$3,$5}' 2>/dev/null > "${PREFIX}/キャラID表.txt"
cat ${PREFIX}/masterfile/master.txt | grep 'text_data VALUES(16,' | awk -F "[,\']" '{printf "%s %s\n" ,$3,$5}' 2>/dev/null > "${PREFIX}/ライブID表.txt"
cat ${PREFIX}/masterfile/master.txt | grep 'text_data VALUES(47,' | awk -F "[,\']" '{printf "%s %s\n" ,$3,$5}' 2>/dev/null > "${PREFIX}/スキルID表.txt"
echo "ファイル名にはキャラのIDが大体入っているのでそのIDで誰の声が入っているかなどがわかります。"
echo "キャラID表.txt にIDが書いてあるので参考にしてみてください。"
echo "動画は"
echo "-b 0000450D -a 608C479F"
echo "でできるので頑張ってください。"
