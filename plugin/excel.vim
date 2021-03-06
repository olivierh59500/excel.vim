command! -nargs=0 Excel call ParseExcel()

if !has("python")
    echo "excel.vim requires support for python"
    finish
endif

au BufRead,BufNewFile *.xls,*.xlam,*.xla,*.xlsb,*.xlsx,*.xlsm,*.xltx,*.xltm,*.xlt :call ParseExcel()


function! ParseExcel()
set nowrap
:python import xlrd
python << EOF
import vim

# for non-ascii characters
def getRealLength(string):
    length = len(string)
    for s in string:
        if ord(s) > 256:
            length += 1
    return length

# get current file name
vim.command("let currfile = expand('%:p')")
currfile = vim.eval("currfile")

# parse sheets
excelobj = xlrd.open_workbook(currfile)
for sheet in excelobj.sheet_names():
    shn = excelobj.sheet_by_name(sheet)
    sheet = sheet.replace(" ", "\\ ")
    rowsnum = shn.nrows
    if not rowsnum:
        continue
    cmd = "tabedit %s" % (sheet)
    vim.command(cmd)

    for n in xrange(rowsnum):
        line = ""
        for val in shn.row_values(n):
            try:
                val = val.replace('\n',' ')
            except AttributeError as e:
                val = str(val).replace('\n', ' ')
            val = isinstance(val,  basestring) and val.strip() \
                    or str(val).strip()
            line += val + ' ' * (30 - getRealLength(val))
        vim.current.buffer.append(line)

# close the first tab
for i in xrange(excelobj.nsheets):
    vim.command("tabp")
vim.command("q!")

EOF
endfunction
