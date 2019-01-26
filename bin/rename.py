from os import rename, listdir, chdir

def rename_files():
    chdir('../data/')
    for filename in listdir('.'):
        
        if filename.endswith('UL.jpg'):
            rename(filename, '0_' + filename.split('_')[0] + '.jpg')

        elif filename.endswith('LL.jpg'):
            rename(filename, '1_' + filename.split('_')[0] + '.jpg')

        elif filename.endswith('UR.jpg'):
            rename(filename, '2_' + filename.split('_')[0] + '.jpg')

        elif filename.endswith('LR.jpg'):
            rename(filename, '3_' + filename.split('_')[0] + '.jpg')
    chdir('../bin/')


if __name__ == '__main__':
    rename_files()
