#Include "%A_ScriptDir%\..\src\Lib\Common.ahk"

ahu.RegisterSuite(CommonSuite)

class CommonSuite extends AutoHotUnitSuite {
    readBool_recognizesTrueVariants() {
        this.assert.isTrue(DD.ReadBool("TestBool", "TrueLower", false))
        this.assert.isTrue(DD.ReadBool("TestBool", "TrueUpper", false))
        this.assert.isTrue(DD.ReadBool("TestBool", "TrueOne", false))
        this.assert.isTrue(DD.ReadBool("TestBool", "TrueSpaced", false))
    }

    readBool_recognizesFalseVariants() {
        this.assert.isFalse(DD.ReadBool("TestBool", "FalseLower", true))
        this.assert.isFalse(DD.ReadBool("TestBool", "FalseZero", true))
    }

    readBool_fallsBackToDefaultWhenKeyMissing() {
        this.assert.isTrue(DD.ReadBool("TestBool", "DoesNotExist", true))
        this.assert.isFalse(DD.ReadBool("TestBool", "DoesNotExist", false))
    }

    readSection_parsesKeyValuePairs() {
        result := DD.ReadSection("TestSection")
        this.assert.equal(result["KeyOne"], "ValueOne")
        this.assert.equal(result["KeyTwo"], "ValueTwo")
    }

    readSection_emptyMapForMissingSection() {
        result := DD.ReadSection("DoesNotExistSection")
        this.assert.equal(result.Count, 0)
    }

    readInt_parsesValidNumber() {
        this.assert.equal(DD.ReadInt("TestInt", "Valid", "0"), 42)
    }

    readInt_fallsBackToDefaultWhenMissing() {
        this.assert.equal(DD.ReadInt("TestInt", "DoesNotExist", "7"), 7)
    }

    readInt_fallsBackToDefaultWhenNotNumeric() {
        ; DD.ReadInt must never throw and kill a script's auto-execute
        ; section over a typo'd ini value — it notifies and falls back.
        this.assert.equal(DD.ReadInt("TestInt", "NotNumeric", "13"), 13)
    }

    gameExe_defaultsToRealProcessName() {
        this.assert.equal(DD.GameExe(), "DunDefGame.exe")
    }

    gameCriterion_wrapsGameExeAsAhkExeCriterion() {
        this.assert.equal(DD.GameCriterion(), "ahk_exe DunDefGame.exe")
    }
}
