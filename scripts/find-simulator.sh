#!/bin/bash
# 시뮬레이터 UDID 찾기
# 우선순위: 1) 인자로 전달된 UDID  2) 부팅된 시뮬레이터  3) 최신 iOS iPhone 중 첫 번째

# 1. 인자로 전달된 경우
if [ -n "$1" ]; then
    echo "$1"
    exit 0
fi

# 2. 부팅된 시뮬레이터
BOOTED=$(xcrun simctl list devices booted | grep -oE '[A-F0-9-]{36}' | head -1)
if [ -n "$BOOTED" ]; then
    echo "$BOOTED"
    exit 0
fi

# 3. 최신 iOS iPhone 시뮬레이터
xcrun simctl list devices available -j | python3 -c "
import sys, json
data = json.load(sys.stdin)['devices']
# iOS 런타임만 필터링하고 버전 내림차순 정렬
runtimes = sorted(
    [(k, v) for k, v in data.items() if 'iOS' in k and v],
    key=lambda x: [int(n) for n in x[0].split('iOS-')[-1].split('-')[:2]],
    reverse=True
)
# 가장 높은 버전에서 iPhone 찾기
for runtime, devices in runtimes:
    for d in devices:
        if d.get('isAvailable') and 'iPhone' in d.get('deviceTypeIdentifier', ''):
            print(d['udid'])
            sys.exit(0)
"
