import re

path = r'c:\Users\User\dev\Data Fight Central\lib\features\drone_racing\screens\drone_racing_screen.dart'
data = open(path, 'r', encoding='utf-8').read()

# Fix tabs - add FPV VIDEO tab before WORLD NEWS
data = data.replace(
    "Tab(text: 'MY HANGAR'),\n                      Tab(text: '\u00c3\u00b0\u0178\u0152\u008d WORLD NEWS'),",
    "Tab(text: 'MY HANGAR'),\n                      Tab(text: '\U0001f3ac FPV VIDEO'),\n                      Tab(text: '\U0001f30d WORLD NEWS'),"
)

# Fix TabBarView - add _buildFpvVideoTab() before _buildWorldNewsTab()
data = data.replace(
    "_buildHangarTab(),\n                _buildWorldNewsTab(),",
    "_buildHangarTab(),\n                _buildFpvVideoTab(),\n                _buildWorldNewsTab(),"
)

open(path, 'w', encoding='utf-8').write(data)
print('Done - tabs fixed')
