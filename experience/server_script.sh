# 在这里配置工作分支
workspace_branch="debug"

# 下面的代码兼容四个环境
debug_branch="debug"
alpha_branch="alpha"
beta_branch="beta"
production_branch="master"

http_server_name="httpserver"
mqtt_server_name="mqtt && websocket"
tcp_server_name="tcpserver.py"


echo "当前工作分支: $workspace_branch"

case $workspace_branch in
"$debug_branch")
    echo " * 初始化 $debug_branch 配置"
    http_service_name="server_http.service"
    http_server_workdir="/home/es/debug/httpserver/antwork_backend"

    mqtt_service_name="server_ws.service"
    mqtt_server_workdir="/home/es/debug/mqtt/antwork_backend"

    tcp_server_workdir="/home/es/debug/mqtt/antwork_backend"
    tcp_server_file="${tcp_server_workdir}/server/tcp_msg/tcpserver.py"
    tcp_server_interpreter="/home/es/debug/new_venv/bin/python3"

    ;;
"$alpha_branch")
    echo " * 初始化 $alpha_branch 配置"
    http_service_name="debug_http.service"
    http_server_workdir="/home/zm/debug/httpserver/antwork_backend"

    mqtt_service_name="debug_ws.service"
    mqtt_server_workdir="/home/zm/debug/mqtt/antwork_backend"

    tcp_server_workdir="/home/zm/debug/mqtt/antwork_backend"
    tcp_server_file="${tcp_server_workdir}/server/tcp_msg/tcpserver.py"
    tcp_server_interpreter="/home/zm/debug/new_venv/bin/python3"

    ;;
"$beta_branch")
    echo " * 初始化 $beta_branch 配置"
    http_service_name="sandbox_http.service"
    http_server_workdir="/home/zm/sandbox/httpserver/antwork_backend"

    mqtt_service_name="sandbox_ws.service"
    mqtt_server_workdir="/home/zm/sandbox/mqtt/antwork_backend"

    tcp_server_workdir="/home/zm/sandbox/mqtt/antwork_backend"
    tcp_server_file="${tcp_server_workdir}/server/tcp_msg/tcpserver.py"
    tcp_server_interpreter="/home/zm/sandbox/new_venv/bin/python3"

    ;;
"$production_branch")
    echo " * 初始化 $production_branch 配置"
    http_service_name="production_http.service"
    http_server_workdir="/usr/nginx/antwork_backend"

    mqtt_service_name="production_ws.service"
    mqtt_server_workdir="/home/zm/tmp/mqtt/antwork_backend"

    tcp_server_workdir="$mqtt_server_workdir"
    tcp_server_file="${tcp_server_workdir}/server/tcp_msg/tcpserver.py"
    tcp_server_interpreter="/home/pro_env/mqtt_env/bin/python3"

    ;;
*)
    echo "Error: 未知的工作分支 $workspace_branch"
    exit 1
    ;;
esac



branch_check(){
    # 检查分支
    work_dir=$1
    work_branch=$2

    echo ""
    echo "【目录检查】"
    echo "工作目录: $work_dir"

    if [[ ! -d "$work_dir" ]]
    then
        echo "Error: 目录不存在 $work_dir"
        exit 1
    fi

    echo "进入工作目录: $work_dir"
    cd $work_dir
    current_dir=$(pwd)
    if [[ "$work_dir" != "$current_dir" ]]
    then
        echo "Error: 请注意，目录切换失败，当前位于 $current_dir"
        exit 1
    fi
    echo "✔ 通过"
    echo ""

    current_branch=$(git rev-parse --abbrev-ref HEAD)
    echo "【分支检查】"

    if [ ! "$current_branch" ]
    then
        echo "Error: 没有找到分支！"
        exit 1
    fi

    git branch

    echo "当前分支：$current_branch"
    echo "工作分支：$work_branch"

    if [[ "$current_branch" != "$work_branch" ]]
    then
        echo "Error: 请注意，httpserver 无法在 $current_branch 分支部署，需要切换到 $work_branch，请妥善处理相关分支后继续!"
        exit 1
    fi

    echo "✔ 通过"
    echo ""
}

branch_update(){
    # 分支更新
    echo "【变更检查】"
    status_result=$(git status)
    echo "变更情况：$status_result"

    if [[ "$status_result" =~ "modified" ]]
    then
        echo ""
        echo "Error: 存在未提交的变更，请妥善处理相关变更后继续！"
        pwd
        exit 1
    fi
    echo "✔ 通过"
    echo ""

    echo "【拉取最新代码】"
    git fetch --all
    git pull
    echo "✔ 完成"
    echo ""

    recent_log=$(git log --oneline -8)
    echo "$recent_log"
}

restart_service(){
    # 重启系统服务
    service_name=$1

    echo ""
    echo "【重启服务 $service_name】"
    systemctl restart $service_name
    systemctl status $service_name
    echo " ✔✔✔ $service_name 服务重启完成。"
    sleep 1
    echo ""
}

restart_script(){
    # 重启自定义脚本
    server_name=$1
    server_interpreter=$2
    server_file=$3

    echo ""
    echo "【重启脚本 $server_name】"

    echo "解释器：$server_interpreter"
    echo "服务脚本：$server_file"
    echo ""

    pid=$(pgrep -f $server_file)
    echo "旧进程 pid: $pid"
    echo ""

    if [ "$pid" ]
    then
        echo "杀死旧进程: $pid"
        echo ""
        kill -9 $pid
    fi

    echo "后台运行 $server_file"
    nohup $server_interpreter $server_file >/dev/null 2>&1 &
    sleep 1
    pid=$(pgrep -f $server_file)
    echo "新进程 pid: $pid"

    if [ ! "$pid" ]
    then
        echo "Error: 启动失败了，请检查指令是否正确"
        echo "Error: ($server_interpreter $server_file)"
        exit 1
    fi

    echo " ✔✔✔ $server_name 服务重启完成。"
    echo ""
}


echo ""
echo "===更新并重启 $http_server_name 项目==="
branch_check $http_server_workdir $workspace_branch
branch_update
restart_service $http_service_name
echo ""


echo ""
echo "===更新并重启 $mqtt_server_name 项目==="
branch_check $mqtt_server_workdir $workspace_branch
branch_update
restart_service $mqtt_service_name
echo ""


echo ""
echo "===重启 $tcp_server_name 脚本==="
branch_check $tcp_server_workdir $workspace_branch
restart_script $tcp_server_name $tcp_server_interpreter $tcp_server_file
echo ""

echo "SUCCESS"
exit 0
