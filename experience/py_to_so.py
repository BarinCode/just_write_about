import os
import traceback
from typing import List

import shutil
import warnings
from distutils.core import setup
from Cython.Build import cythonize


class Py2So(object):
    """
    py项目编译成so文件
    """

    def __init__(self, project_path: str, filter_files: list = None, filter_dirs: list = None):
        """
        :param project_path: 项目所在path
        :param filter_files:
        :param filter_dirs:
        """
        self.project_path = project_path
        self.project_name = os.path.basename(project_path)
        self.current_dir = os.getcwd()
        self.build_param = None

        self.filter_files = filter_files if filter_files else []
        self.filter_dirs = filter_dirs if filter_dirs else []
        self.filter_types = [".pyc", ".c"]

    @staticmethod
    def copy_file(target_dir: str, file_name: str):
        """
        拷贝文件
        @param target_dir:
        @param file_name:
        @return:
        """
        if not os.path.exists(target_dir):
            os.makedirs(target_dir)
        shutil.copy(file_name, target_dir)

    def filter_target_types(self, file_name: str):
        """
        过滤文件类型
        @param file_name:
        @return:
        """
        for file_type in self.filter_types:
            if file_name.endswith(file_type):
                return True
        return False

    def filter_target_files(self, file_name: str):
        """
        过滤目标文件
        @param file_name:
        @return:
        """
        for file in self.filter_files:
            if file in file_name:
                return True
        return False

    def filter_target_dir(self, root: str):
        """
        打到目标文件夹
        @param root:
        @return:
        """
        for p in self.filter_dirs:
            if root.find(p) >= 0:
                return True
        return False

    @staticmethod
    def remove_file(root: str, file_name: str):
        """
        删除.c文件以保证每次都进行so文件生成
        :param root:
        :param file_name:
        :return:
        """
        name, _ = file_name.split(".")
        c_file = os.path.join(root, name + ".c")
        if os.path.exists(c_file):
            os.remove(c_file)

    @staticmethod
    def rename_file(file_path):
        """
        重命名so文件
        :param file_path:
        :return:
        """
        for root, dirs, files in os.walk(file_path):
            for file_name in files:
                if file_name.endswith(".so"):
                    name = file_name.split(".")[0]
                    ori_file = os.path.join(root, file_name)
                    so_file = os.path.join(root, name + ".so")
                    os.rename(ori_file, so_file)

    def set_build_param(self, build_dir: str):
        """
        开始构建参数
        @param build_dir:
        @return:
        """
        self.build_param = [
            "build_ext",
            "-b", build_dir,
            "-t", self.current_dir + "/tmp"
        ]

    def build(self):
        """
        开始构建
        @return:
        """
        current_file = ""
        build_dir = ""
        try:
            for root, dirs, files in os.walk(self.project_path):
                build_dir = self.current_dir + "/build"
                if self.filter_target_dir(root):
                    continue
                _, sub_dir = root.split(self.project_name)
                if len(sub_dir) > 0:
                    build_dir += sub_dir
                if os.path.exists(build_dir):
                    shutil.rmtree(build_dir)
                for file in files:
                    current_file = os.path.join(root, file)

                    if self.filter_target_types(file):
                        continue

                    if self.filter_target_files(file):
                        continue
                    if not file.endswith(".py"):
                        self.copy_file(build_dir, current_file)
                        continue
                    self.set_build_param(build_dir)
                    name, _ = current_file.split(".")
                    so_file = os.path.join(root, name + ".so")
                    setup(ext_modules=cythonize([current_file]), script_args=self.build_param,
                          name=so_file)
                    print(so_file)
                    self.remove_file(root, current_file)
            self.rename_file(self.current_dir + "/build")

        except Exception as e:
            traceback.print_exc()
            if os.path.exists(build_dir):
                shutil.rmtree(build_dir)
            raise Exception("build {} failed".format(current_file))


if __name__ == "__main__":
    """

    """
    warnings.filterwarnings("ignore")
    main_func = "start_routeplanning_service.py"

    # TODO 优化协议的内容， for example awlink2
    project_path = os.path.abspath(os.path.dirname(os.path.abspath(__file__)) + os.path.sep + "SkyBlock")
    filter_files = ["yaml2header.py", main_func]
    filter_dirs = ["awlink2/tools", ".git", ".vscode", ".idea", "release"]

    ps = Py2So(project_path=project_path, filter_files=filter_files, filter_dirs=filter_dirs)
    ps.build()
    ps.copy_file(project_path + "/release/build", project_path + "/" + main_func)

