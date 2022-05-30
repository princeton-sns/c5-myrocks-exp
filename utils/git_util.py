import subprocess
import os
import shlex


def build_client(config):
    src_path = os.path.join(config["client_src_directory"], "oltpbench")
    subprocess.call(shlex.split("ant build"), cwd=src_path)


def compile_make(config):
    src_path = config["server_src_directory"]
    build_path = config["server_build_directory"]

    os.makedirs(build_path, exist_ok=True)
    if "server_debug" in config and config["server_debug"]:
        subprocess.call(shlex.split("cmake {} -DCMAKE_BUILD_TYPE=Debug -DWITH_SSL=system \
	                                -DMYSQL_MAINTAINER_MODE=1 -DENABLE_DTRACE=0 -DWITH_ZSTD=/usr \
                                    -DCMAKE_INSTALL_PREFIX={}".format(src_path, build_path)),
                        cwd=src_path)
    else:
        subprocess.call(shlex.split('cmake {} -DCMAKE_BUILD_TYPE=RelWithDebInfo -DWITH_SSL=system -DWITH_ZLIB=bundled \
	                                -DWITH_LZ4=/usr/lib/x86_64-linux-gnu -DWITH_ZSTD=system -DWITH_JEMALLOC=/usr/local/lib \
	                                -DMYSQL_MAINTAINER_MODE=0 -DENABLED_LOCAL_INFILE=1 \
	                                -DCMAKE_C_FLAGS="-DHAVE_JEMALLOC" -DCMAKE_CXX_FLAGS="-march=native -DHAVE_JEMALLOC" \
	                                -DCMAKE_INSTALL_PREFIX={}'.format(src_path, build_path)),
                        cwd=src_path)

    subprocess.call(shlex.split("make -j8 -Otarget"), cwd=src_path)
    subprocess.call(shlex.split("make install"), cwd=src_path)

    bin_path = os.path.join(src_path, "bin")
    # os.makedirs(bin_path, exist_ok=True)
    # if 'make_collect_bins' in config:
    #     for f in config['make_collect_bins']:
    #         shutil.copy2(os.path.join(server_src_directory, f),
    #                      os.path.join(bin_path, os.path.basename(f)))
    return bin_path


def get_current_branch(src_directory, target="HEAD"):
    return subprocess.check_output(["git", "rev-parse", target],
                                   cwd=src_directory).decode('utf-8').rstrip()


def get_current_branch_short(src_directory):
    return subprocess.check_output(["git", "rev-parse", "--abbrev-ref", "HEAD"],
                                   cwd=src_directory).decode('utf-8').rstrip()


def checkout_commit(src_directory, src_commit_hash):
    subprocess.call(shlex.split("git checkout {}".format(src_commit_hash)),
                    cwd=src_directory)
    subprocess.call(shlex.split("git submodule update --init"),
                    cwd=src_directory)


def stash_changes(src_directory):
    subprocess.call(["git", "stash"], cwd=src_directory)


def pop_stashed_changes(src_directory):
    subprocess.call(["git", "stash", "pop"], cwd=src_directory)


def clean_working_directory(src_directory):
    return subprocess.run(['git', 'status', '--untracked-files=no', '--porcelain'], cwd=src_directory).returncode == 0


def remake_binaries(config):
    server_src_directory = config["server_src_directory"]

    # Build client
    build_client(config)

    # Build server
    clean = clean_working_directory(server_src_directory)
    if not clean:
        stash_changes(server_src_directory)
    current_branch = get_current_branch(server_src_directory)
    current_branch_short = get_current_branch_short(server_src_directory)
    print(current_branch)
    checked_out = False
    if "server_src_commit_hash" in config:
        server_src_commit_hash = config["server_src_commit_hash"]
        target_branch = get_current_branch(
            server_src_directory, server_src_commit_hash)
        if target_branch != current_branch:
            checkout_commit(server_src_directory, server_src_commit_hash)
            checked_out = True
    else:
        server_src_commit_hash = current_branch
    compile_make(config)
    if checked_out:
        checkout_commit(server_src_directory, current_branch_short)
    if not clean:
        pop_stashed_changes(server_src_directory)
