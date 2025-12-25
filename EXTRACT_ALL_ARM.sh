#!/bin/bash
echo "🔥 EXTRACTING ALL 38 ARM PRESENTS! 🎁"
echo "========================================"

cd "not sure if you like"
EXTRACTED=0

# Extract everything to ../ARM_Components organized by type
for zip in *.zip; do
    NAME="${zip%.zip}"
    echo "📦 $NAME..."
    
    # Determine category and extract
    case "$NAME" in
        *audio*|*alsa*|*speaker*)
            unzip -q "$zip" -d ../ARM_Components/audio/ 2>/dev/null
            ;;
        *gpu*|*mesa*)
            unzip -q "$zip" -d ../ARM_Components/drivers/ 2>/dev/null
            ;;
        *devicetree*|*m1n1*|*u-boot*)
            unzip -q "$zip" -d ../ARM_Components/bootloaders/ 2>/dev/null
            ;;
        *docs*|*github.io*)
            unzip -q "$zip" -d ../ARM_Components/docs/ 2>/dev/null
            ;;
        *linux*)
            unzip -q "$zip" -d ../ARM_Components/kernel/ 2>/dev/null
            ;;
        *)
            unzip -q "$zip" -d ../ARM_Components/tools/ 2>/dev/null
            ;;
    esac
    
    EXTRACTED=$((EXTRACTED + 1))
    if [ $((EXTRACTED % 5)) -eq 0 ]; then
        echo "   ✅ $EXTRACTED/38 complete..."
    fi
done

echo ""
echo "🎉 ALL 38 PRESENTS EXTRACTED!"
cd ..
echo ""
echo "📊 Final ARM Components:"
du -sh ARM_Components/* 2>/dev/null
echo ""
du -sh ARM_Components
