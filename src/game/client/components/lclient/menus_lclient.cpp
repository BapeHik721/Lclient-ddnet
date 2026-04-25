#include <engine/shared/config.h>
#include <game/client/components/menus.h>
#include <game/client/gameclient.h>
#include <game/client/ui.h>
#include <game/localization.h>

void CMenus::RenderSettingsLClient(CUIRect MainView)
{
	CUIRect Label, Button, Left, Right;
	char aBuf[128];

	// Title
	MainView.HSplitTop(30.0f, &Label, &MainView);
	Ui()->DoLabel(&Label, Localize("L-Client Advanced Cheats"), 20.0f, TEXTALIGN_MC);
	MainView.HSplitTop(20.0f, nullptr, &MainView);

	// Split view into two columns like TClient settings
	MainView.VSplitMid(&Left, &Right, 20.0f);
	Left.Draw(ColorRGBA(0.0f, 0.0f, 0.0f, 0.1f), IGraphics::CORNER_ALL, 5.0f);
	Right.Draw(ColorRGBA(0.0f, 0.0f, 0.0f, 0.1f), IGraphics::CORNER_ALL, 5.0f);
	Left.Margin(6.0f, &Left);
	Right.Margin(6.0f, &Right);

	static CButtonContainer s_AimbotBindReaderButton;
	static CButtonContainer s_AimbotBindClearButton;
	static CButtonContainer s_TriggerbotBindReaderButton;
	static CButtonContainer s_TriggerbotBindClearButton;

	// --- AIMBOT SECTION (Left Column) ---
	{
		Left.HSplitTop(25.0f, &Label, &Left);
		Ui()->DoLabel(&Label, Localize("Aimbot"), 18.0f, TEXTALIGN_ML);
		Left.HSplitTop(10.0f, nullptr, &Left);

		// Enable Aimbot
		Left.HSplitTop(20.0f, &Button, &Left);
		if(DoButton_CheckBox(&g_Config.m_LcLowAimbot, Localize("Enable Aimbot"), g_Config.m_LcLowAimbot, &Button))
			g_Config.m_LcLowAimbot ^= 1;

		// Aimbot On Key
		Left.HSplitTop(5.0f, nullptr, &Left);
		Left.HSplitTop(20.0f, &Button, &Left);
		if(DoButton_CheckBox(&g_Config.m_LcLowAimbotOnKey, Localize("Aimbot only on key"), g_Config.m_LcLowAimbotOnKey, &Button))
			g_Config.m_LcLowAimbotOnKey ^= 1;

		Left.HSplitTop(5.0f, nullptr, &Left);
		Left.HSplitTop(20.0f, &Button, &Left);
		if(DoButton_CheckBox(&g_Config.m_LcLowVisibleOnly, Localize("Target visible only"), g_Config.m_LcLowVisibleOnly, &Button))
			g_Config.m_LcLowVisibleOnly ^= 1;

		// Key Bind (If on key)
		if(g_Config.m_LcLowAimbotOnKey)
		{
			Left.HSplitTop(5.0f, nullptr, &Left);
			DoLine_KeyReader(Left, s_AimbotBindReaderButton, s_AimbotBindClearButton, Localize("Aimbot key"), "+l_aim");
		}

		// FOV Slider
		Left.HSplitTop(15.0f, nullptr, &Left);
		Left.HSplitTop(15.0f, &Label, &Left);
		str_format(aBuf, sizeof(aBuf), "%s: %d", Localize("Field of View (FOV)"), g_Config.m_LcLowAimbotFOV);
		Ui()->DoLabel(&Label, aBuf, 14.0f, TEXTALIGN_ML);
		Left.HSplitTop(20.0f, &Button, &Left);
		g_Config.m_LcLowAimbotFOV = (int)(Ui()->DoScrollbarH(&g_Config.m_LcLowAimbotFOV, &Button, g_Config.m_LcLowAimbotFOV / 360.0f) * 360.0f);
		if(g_Config.m_LcLowAimbotFOV < 1) g_Config.m_LcLowAimbotFOV = 1;

		// Smoothing Slider
		Left.HSplitTop(10.0f, nullptr, &Left);
		Left.HSplitTop(15.0f, &Label, &Left);
		str_format(aBuf, sizeof(aBuf), "%s: %d%%", Localize("Smoothing (0=Snappy)"), g_Config.m_LcLowAimbotSmoothing);
		Ui()->DoLabel(&Label, aBuf, 14.0f, TEXTALIGN_ML);
		Left.HSplitTop(20.0f, &Button, &Left);
		g_Config.m_LcLowAimbotSmoothing = (int)(Ui()->DoScrollbarH(&g_Config.m_LcLowAimbotSmoothing, &Button, g_Config.m_LcLowAimbotSmoothing / 100.0f) * 100.0f);
	}

	// --- TRIGGERBOT SECTION (Right Column) ---
	{
		Right.HSplitTop(25.0f, &Label, &Right);
		Ui()->DoLabel(&Label, Localize("Triggerbot"), 18.0f, TEXTALIGN_ML);
		Right.HSplitTop(10.0f, nullptr, &Right);

		// Weapon Trigger
		Right.HSplitTop(20.0f, &Button, &Right);
		if(DoButton_CheckBox(&g_Config.m_LcLowTriggerbot, Localize("Auto-Fire (Weapon)"), g_Config.m_LcLowTriggerbot, &Button))
			g_Config.m_LcLowTriggerbot ^= 1;

		// Hook Trigger
		Right.HSplitTop(5.0f, nullptr, &Right);
		Right.HSplitTop(20.0f, &Button, &Right);
		if(DoButton_CheckBox(&g_Config.m_LcLowTriggerbotHook, Localize("Auto-Hook (Target)"), g_Config.m_LcLowTriggerbotHook, &Button))
			g_Config.m_LcLowTriggerbotHook ^= 1;

		Right.HSplitTop(5.0f, nullptr, &Right);
		Right.HSplitTop(20.0f, &Button, &Right);
		if(DoButton_CheckBox(&g_Config.m_LcLowTriggerbotOnKey, Localize("Triggerbot only on key"), g_Config.m_LcLowTriggerbotOnKey, &Button))
			g_Config.m_LcLowTriggerbotOnKey ^= 1;
		if(g_Config.m_LcLowTriggerbotOnKey)
		{
			Right.HSplitTop(5.0f, nullptr, &Right);
			DoLine_KeyReader(Right, s_TriggerbotBindReaderButton, s_TriggerbotBindClearButton, Localize("Triggerbot key"), "+l_trigger");
		}

		// Range Slider
		Right.HSplitTop(15.0f, nullptr, &Right);
		Right.HSplitTop(15.0f, &Label, &Right);
		str_format(aBuf, sizeof(aBuf), "%s: %d%%", Localize("Max Distance"), g_Config.m_LcLowAimbotRange);
		Ui()->DoLabel(&Label, aBuf, 14.0f, TEXTALIGN_ML);
		Right.HSplitTop(20.0f, &Button, &Right);
		g_Config.m_LcLowAimbotRange = (int)(Ui()->DoScrollbarH(&g_Config.m_LcLowAimbotRange, &Button, g_Config.m_LcLowAimbotRange / 100.0f) * 100.0f);
	}
}
