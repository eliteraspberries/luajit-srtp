/\\$/N;s/ *\\\n */ /g
/[/][*]/ {
    /[*][/]$/! {
        N;s/\n//g
    }
}
s/ *[/][*].*[*][/] *//
/^typedef / {
    /[{]/ {
        /[}]/! {
            N;s/ *\n */ /g
        }
    }
}
/^#/! {
/[(]/ {
    /[)][;]$/! {
        N;s/[(]\n */(/g
        N;s/[,]\n */, /g
    }
}
}
/[,] *$/N;s/[,] *\n */, /g
/^$/d
