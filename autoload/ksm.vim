scriptencoding utf-8
let s:save_cpo = &cpoptions
set cpoptions&vim
if exists('s:is_loaded')
    finish
endif
let s:is_loaded = 1
let s:script_dir = expand('<sfile>:p:h')

" autocmd! BufWritePost ksm.vim source ksm.vim

py3 << EOF
import win32con
import win32gui
import win32api
import win32ui
import win32process
import numpy as np
import vim
import os
import sys
from os.path import abspath, exists
import subprocess
import time
import zlib
import re

class Ksm():
    FONT_WIDTH = 5
    FONT_HIGHT = 10
    FONT_CHANNEL = 4
    TRAIN_LABEL = ('0','1','2','3','4','5','6','7','8','9','/',' ')
    TRAIN_DATA = np.frombuffer(zlib.decompress(
    b"x\x9c\xcdU[\n\x00 \x08\xeb\xfe\x976\xe8+\xc4Y\xe6\xd0\x06A\xd9c\x99\xd3\xc6\x88ADV\xdb\xc7\xba\xcf\xb6Y\xbc\x0c\xe8\xf3"  +
    b"\x10G\x85\xed\x157\xf1\xf0\xb8\xa3\xe3\x9d\x93\x19\x93\x8c\x1f\xde=\xbatu\xd2\xd6M\x0e\xa09\xef\xed\x19\xbeX\x1c'\x1d\xa0"+
    b"s\x90\xad*\x1e\xd1z\xa5\xf7\xbd\xd4:\x8b7\x83h\xccYk\x90-\x03\xe6\x9bv\xfe\x1f\x8c\xbbt\xe5G\xa5\x86*4\xf53&\x82;\x93{"
    ), dtype='uint8').reshape(len(TRAIN_LABEL), FONT_HIGHT*FONT_WIDTH*FONT_CHANNEL)
    def __init__(self):
        self.chart_path = vim.call("expand","%:p")
        self.editor_path = abspath(vim.call("expand","%:p:h:h:h:h")+"\\editor.exe")
        self.mania_path = abspath(vim.call("expand","%:p:h:h:h:h")+"\\kshootmania.exe")
        assert exists(self.editor_path) and exists(self.mania_path), \
               "譜面ファイルはK-SHoot Maniaの管理化にある必要がある"

    @staticmethod
    def find_hwnds_for_pid(pid):
        def callback(hwnd, hwnds):
            if win32gui.IsWindowVisible (hwnd) and win32gui.IsWindowEnabled(hwnd):
                _, found_pid = win32process.GetWindowThreadProcessId(hwnd)
                if found_pid == pid:
                    hwnds.append(hwnd)
            return True
        hwnds = []
        win32gui.EnumWindows(callback, hwnds)
        return hwnds

    def launch(self):
        self.process = subprocess.Popen([self.editor_path, self.chart_path])
        timeout = 5 #sec
        start = time.time()
        while time.time() - start < timeout:
            hwnds = Ksm.find_hwnds_for_pid(self.process.pid)
            if len(hwnds) > 0:
                break
        assert len(hwnds) == 1, "K-Shoot Editorが正常に起動できない"
        self.hwnd = hwnds[0]

    def capture(self):
        x0, y0, x1, y1 = win32gui.GetWindowRect(self.hwnd)
        w, h = 70, 30
        wDC   = win32gui.GetWindowDC(self.hwnd)
        dcObj = win32ui.CreateDCFromHandle(wDC)
        cDC   = dcObj.CreateCompatibleDC()
        dataBitMap = win32ui.CreateBitmap()
        dataBitMap.CreateCompatibleBitmap(dcObj, w, h)
        cDC.SelectObject(dataBitMap)
        cDC.BitBlt((0, 0), (w, h), dcObj, (x1-x0-w, y1-y0-h), win32con.SRCCOPY)
        im = dataBitMap.GetBitmapBits(False)
        img = np.array(im, dtype='uint8')
        img.shape = (h, w, 4)
        # release
        dcObj.DeleteDC()
        cDC.DeleteDC()
        win32gui.ReleaseDC(self.hwnd, wDC)
        win32gui.DeleteObject(dataBitMap.GetHandle())
        return img

    @staticmethod
    def _predict(test_data):
        return Ksm.TRAIN_LABEL[np.argmin(np.linalg.norm(Ksm.TRAIN_DATA - test_data.flatten(),axis=1))]

    def predict(self):
        img = self.capture()
        carved = [[img[1+y*Ksm.FONT_HIGHT:1+(y+1)*Ksm.FONT_HIGHT,
                       8+x*Ksm.FONT_WIDTH:8+(x+1)*Ksm.FONT_WIDTH]
                  for x in range(9)]
                 for y in range(2)]
        bars = ''.join(map(Ksm._predict, carved[0][0:3])).strip()
        frac = ''.join(map(Ksm._predict, carved[1][2:9])).strip()
        num, denom = frac.split('/')
        return int(bars),int(num),int(denom)

    @staticmethod
    def _goto(bars, num, denom):
        count_bar = 0
        jump_tag = []
        for i,line in enumerate(vim.current.buffer):
            if re.match('^--$', line):
                count_bar += 1
            if re.match('^[0-2]{4}\|[0-2]{2}\|[\w:-]{2}$', line) and count_bar == bars:
                jump_tag.append(i+1)
            if count_bar > bars:
                break
        vim.command(':'+str(jump_tag[len(jump_tag)*(num-1)//denom]))

    def goto(self):
        self._goto(*self.predict())

EOF

function ksm#start()
    py3 ksm = Ksm();ksm.launch()
endfunction

function ksm#goto()
    py3 ksm.goto()
endfunction

let &cpoptions = s:save_cpo
unlet s:save_cpo
