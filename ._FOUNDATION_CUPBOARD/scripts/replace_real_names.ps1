# DFC Real Name Replacement Script
# Replaces ALL real fighter/coach/promoter/gym names with fictional DFC characters
# to avoid legal liability from associating real people with fictional promotions

$libPath = "c:\Users\User\dev\Data Fight Central\lib"

# ============================================================
# FICTIONAL DFC CHARACTER ROSTER
# ============================================================
# Each real name maps to a fictional DFC-original character

$replacements = @(
    # ========== PRIMARY TRIO (My Passes screenshot) ==========
    @{ Old = 'ROBERT WHITTAKER'; New = 'MARCUS TORRES' },
    @{ Old = 'Robert Whittaker'; New = 'Marcus Torres' },
    @{ Old = 'robert_whittaker'; New = 'marcus_torres' },
    @{ Old = '@robwhittaker'; New = '@marcustorres' },
    @{ Old = 'fighter_whittaker'; New = 'fighter_torres' },
    @{ Old = "'The Reaper'"; New = "'The Phoenix'" },

    @{ Old = 'COACH EUGENE BAREMAN'; New = 'COACH RAY MITCHELL' },
    @{ Old = 'Coach Eugene Bareman'; New = 'Coach Ray Mitchell' },
    @{ Old = 'Eugene Bareman'; New = 'Ray Mitchell' },
    @{ Old = 'coach_eugene_bareman'; New = 'coach_ray_mitchell' },
    @{ Old = '@eugenebareman'; New = '@raymitchell' },
    @{ Old = 'Coach Bareman'; New = 'Coach Mitchell' },

    @{ Old = 'PHIL DARU'; New = 'JAKE MORRISON' },
    @{ Old = 'Phil Daru Strength'; New = 'Jake Morrison Strength' },
    @{ Old = 'Phil Daru Strong'; New = 'Jake Morrison Performance' },
    @{ Old = 'Phil Daru'; New = 'Jake Morrison' },
    @{ Old = 'Daru Strong'; New = 'Morrison Performance' },

    # ========== MAJOR FIGHTERS ==========
    @{ Old = 'Conor "Notorious" McGregor'; New = 'Declan "The Storm" Hayes' },
    @{ Old = 'conor_mcgregor'; New = 'declan_hayes' },
    @{ Old = 'Conor McGregor'; New = 'Declan Hayes' },
    @{ Old = "McGregor's home gym"; New = "Hayes's home gym" },
    @{ Old = 'McGregor vs Pimblett'; New = 'Hayes vs O''Brien' },
    @{ Old = 'Makhachev vs McGregor'; New = 'Karimov vs Hayes' },
    @{ Old = 'McGregor, Bisping'; New = 'Hayes, Hargrove' },
    @{ Old = 'McGregor'; New = 'Hayes' },

    @{ Old = 'Alex "Poatan" Pereira'; New = 'Rafael "Thunder" Santos' },
    @{ Old = 'alex_pereira'; New = 'rafael_santos' },
    @{ Old = 'Pereira vs Ankalaev'; New = 'Santos vs Aliyev' },
    @{ Old = 'Alex Pereira'; New = 'Rafael Santos' },
    @{ Old = 'Pereira'; New = 'Santos' },

    @{ Old = 'Israel Adesanya'; New = 'Elijah Okafor' },
    @{ Old = 'Adesanya vs Whittaker'; New = 'Okafor vs Torres' },
    @{ Old = 'Du Plessis vs. Adesanya'; New = 'Van Zyl vs. Okafor' },
    @{ Old = 'Adesanya'; New = 'Okafor' },

    @{ Old = 'Amanda Serrano'; New = 'Sofia Reyes' },
    @{ Old = 'Serrano vs Taylor'; New = 'Reyes vs Brennan' },
    @{ Old = 'Serrano'; New = 'Reyes' },

    @{ Old = 'Katie Taylor'; New = 'Niamh Brennan' },

    @{ Old = "Zhang Weili '\u5f20\u4f1f\u4e3d'"; New = "Lin Mei Chen" },
    @{ Old = 'Zhang Weili'; New = 'Lin Mei Chen' },
    @{ Old = 'Yan Xiaonan'; New = 'Bai Xiaoli' },

    @{ Old = 'Valentina "Bullet" Shevchenko'; New = 'Katarina "Swift" Petrov' },
    @{ Old = 'valentina_shevchenko'; New = 'katarina_petrov' },
    @{ Old = 'Valentina Shevchenko'; New = 'Katarina Petrov' },
    @{ Old = 'Shevchenko'; New = 'Petrov' },

    @{ Old = 'Claressa Shields'; New = 'Destiny Monroe' },
    @{ Old = 'Shields Night'; New = 'Monroe Night' },
    @{ Old = 'GWOAT'; New = 'Champion' },

    @{ Old = 'Canelo Alvarez'; New = 'Carlos Mendoza' },
    @{ Old = 'Canelo: Undisputed'; New = 'Mendoza: Undisputed' },
    @{ Old = 'Canelo'; New = 'Mendoza' },

    @{ Old = 'Rodtang Jitmuangnon'; New = 'Somsak Kiatmook' },
    @{ Old = 'Rodtang'; New = 'Somsak' },

    @{ Old = 'Cris Cyborg'; New = 'Valeria Cruz' },
    @{ Old = 'Cyborg'; New = 'Cruz' },

    @{ Old = 'Naoya Inoue'; New = 'Kenji Tanaka' },
    @{ Old = 'Inoue Third Division'; New = 'Tanaka Third Division' },
    @{ Old = 'Inoue'; New = 'Tanaka' },

    @{ Old = "Sean O'Malley"; New = 'Ryan Calloway' },
    @{ Old = "O'Malley"; New = 'Calloway' },

    @{ Old = 'Jon Jones'; New = 'Devon Mitchell' },

    @{ Old = 'Khabib Nurmagomedov'; New = 'Rashid Karimov' },
    @{ Old = 'Khabib Training HQ'; New = 'Karimov Training HQ' },
    @{ Old = 'Khabib'; New = 'Karimov' },

    @{ Old = 'Paddy Pimblett'; New = 'Liam O''Brien' },
    @{ Old = 'PIMBLETT vs HOLLOWAY'; New = 'O''BRIEN vs NAKAMURA' },
    @{ Old = 'Pimblett'; New = 'O''Brien' },

    @{ Old = 'Tai Tuivasa'; New = 'Mako Tua' },
    @{ Old = "'Bam Bam'"; New = "'The Wave'" },
    @{ Old = 'Team Tuivasa / Izu MMA'; New = 'Team Pacific / Island MMA' },
    @{ Old = 'Tuivasa'; New = 'Tua' },

    @{ Old = 'Alexander Volkanovski'; New = 'Tyler Reid' },
    @{ Old = 'Volkanovski'; New = 'Reid' },

    @{ Old = 'Max Holloway'; New = 'Kai Nakamura' },
    @{ Old = 'Holloway'; New = 'Nakamura' },

    @{ Old = 'Dricus du Plessis'; New = 'Pieter Van Zyl' },
    @{ Old = 'du Plessis'; New = 'Van Zyl' },

    @{ Old = 'Islam Makhachev'; New = 'Rashid Karimov' },
    @{ Old = 'Makhachev'; New = 'Karimov' },

    @{ Old = 'Ilia Topuria'; New = 'Mateo Navarro' },
    @{ Old = 'Topuria'; New = 'Navarro' },

    @{ Old = 'Magomed Ankalaev'; New = 'Murad Aliyev' },
    @{ Old = 'Ankalaev'; New = 'Aliyev' },

    @{ Old = 'Dan Hooker'; New = 'Nathan Cross' },
    @{ Old = 'Hooker'; New = 'Cross' },

    @{ Old = 'Kai Kara-France'; New = 'Tama Rawiri' },
    @{ Old = 'Kara-France'; New = 'Rawiri' },

    @{ Old = 'Carlos Ulberg'; New = 'Zane Kohere' },

    @{ Old = 'Ciryl Gane'; New = 'Antoine Marchand' },

    @{ Old = 'Stamp Fairtex'; New = 'Suri Phanomrung' },
    @{ Old = 'stamp_fairtex'; New = 'suri_phanomrung' },

    @{ Old = 'Amanda Nunes'; New = 'Daniela Costa' },
    @{ Old = 'Nunes'; New = 'Costa' },

    @{ Old = 'Dustin Poirier'; New = 'Derek Stone' },
    @{ Old = '@dustinpoirier'; New = '@derekstone' },
    @{ Old = 'Poirier'; New = 'Stone' },

    @{ Old = 'Artur Beterbiev'; New = 'Artem Volkov' },
    @{ Old = 'Beterbiev'; New = 'Volkov' },

    @{ Old = 'Dmitry Bivol'; New = 'Sergei Kozlov' },
    @{ Old = 'Bivol'; New = 'Kozlov' },

    @{ Old = 'Charles Oliveira'; New = 'Lucas Ferreira' },
    @{ Old = 'Oliveira'; New = 'Ferreira' },

    @{ Old = 'Michael Chandler'; New = 'Jake Lawson' },
    @{ Old = 'Chandler'; New = 'Lawson' },

    @{ Old = 'Gilbert Burns'; New = 'Andre Silva' },

    @{ Old = 'Holly Holm'; New = 'Sarah Blake' },

    @{ Old = 'Daniel Cormier'; New = 'Marcus Grant' },
    @{ Old = 'Cormier'; New = 'Grant' },

    @{ Old = 'Ronda Rousey'; New = 'Jessica Palmer' },
    @{ Old = 'Rousey'; New = 'Palmer' },

    @{ Old = 'Georges St-Pierre'; New = 'Jean-Luc Moreau' },

    @{ Old = 'Tyson Fury'; New = 'Connor McKinnon' },
    @{ Old = 'Fury'; New = 'McKinnon' },

    @{ Old = 'Terence Crawford'; New = 'Marcus Webb' },

    @{ Old = 'Superbon'; New = 'Narong' },
    @{ Old = 'Tawanchai'; New = 'Apichai' },

    @{ Old = 'Michael Bisping'; New = 'James Hargrove' },
    @{ Old = 'Kayla Harrison'; New = 'Taylor Hunt' },
    @{ Old = 'Oleksandr Usyk'; New = 'Viktor Marchenko' },
    @{ Old = 'Merab Dvalishvili'; New = 'Giorgi Tsiklauri' },
    @{ Old = 'Junto Nakatani'; New = 'Hiro Sakata' },
    @{ Old = 'David Benavidez'; New = 'Diego Castillo' },
    @{ Old = 'Arman Tsarukyan'; New = 'Aram Kazarian' },
    @{ Old = 'Jessica Andrade'; New = 'Lucia Fernandez' },
    @{ Old = "Patricio.*Freire"; New = 'Roberto Aguiar' },
    @{ Old = 'A.J. McKee'; New = 'Jordan Brooks' },
    @{ Old = 'Alycia Baumgardner'; New = 'Maya Henderson' },
    @{ Old = 'Chantelle Cameron'; New = 'Lauren Mitchell' },
    @{ Old = 'Seniesa Estrada'; New = 'Maria Vasquez' },
    @{ Old = 'Ham Seo Hee'; New = 'Ji-Yeon Park' },
    @{ Old = 'Usman Nurmagomedov'; New = 'Timur Karimov' },
    @{ Old = 'Haggerty'; New = 'Whitfield' },

    @{ Old = 'Dana White'; New = 'the promotion CEO' },
    @{ Old = 'Bob Arum'; New = 'the veteran promoter' },

    # ========== GYM NAMES ==========
    @{ Old = 'City Kickboxing'; New = 'Summit Fight Academy' },
    @{ Old = 'Tiger Muay Thai'; New = 'Golden Dragon Muay Thai' },
    @{ Old = 'American Top Team'; New = 'Elite Combat Team' },
    @{ Old = 'American Kickboxing Academy'; New = 'Pacific Kickboxing Academy' },
    @{ Old = 'Jackson Wink MMA Academy'; New = 'Desert Storm MMA Academy' },
    @{ Old = 'Straight Blast Gym'; New = 'Celtic Combat Gym' },
    @{ Old = 'SBG Ireland'; New = 'Celtic Combat Ireland' },
    @{ Old = 'Kill Cliff FC'; New = 'Coastal Fight Club' },
    @{ Old = 'Sanford MMA'; New = 'Coastal MMA' },
    @{ Old = 'Renzo Gracie Academy'; New = 'Legacy Grappling Academy' },
    @{ Old = 'Renzo Gracie'; New = 'Legacy Grappling' },
    @{ Old = 'Rickson Gracie'; New = 'Master Kenzo Yamamoto' },
    @{ Old = 'London Shootfighters'; New = 'London Combat Academy' },
    @{ Old = 'Gracie Jiu-Jitsu Melbourne'; New = 'Southern Cross BJJ Melbourne' },
    @{ Old = 'Gracie Jiu-Jitsu Smeaton Grange'; New = 'Southern Cross BJJ Smeaton Grange' },
    @{ Old = 'Black Tiger Fight Club'; New = 'Black Panther Fight Club' },
    @{ Old = 'Top Rank Boxing'; New = 'Premier Boxing Promotions' },
    @{ Old = 'Top Rank'; New = 'Premier Boxing' },
    @{ Old = 'Eagle FC'; New = 'Mountain FC' },

    # ========== PROMOTION NAMES ==========
    @{ Old = 'Ultimate Promotions Legends Fight Night'; New = 'DFC Championship Series' },
    @{ Old = 'Ultimate Promotions'; New = 'DFC Promotions' },
    @{ Old = 'Cage Warriors'; New = 'Cage Titans' }
)

Write-Host "Starting DFC Real Name Replacement..."
Write-Host "Processing $($replacements.Count) replacement rules across lib/**/*.dart"

$totalReplacements = 0
$filesModified = @{}

foreach ($rule in $replacements) {
    $old = $rule.Old
    $new = $rule.New

    # Get all .dart files containing the old string
    $files = Get-ChildItem -Path $libPath -Filter "*.dart" -Recurse | Where-Object {
        (Get-Content $_.FullName -Raw -ErrorAction SilentlyContinue) -match [regex]::Escape($old)
    }

    foreach ($file in $files) {
        $content = Get-Content $file.FullName -Raw
        $count = ([regex]::Matches($content, [regex]::Escape($old))).Count
        if ($count -gt 0) {
            $content = $content -replace [regex]::Escape($old), $new
            Set-Content -Path $file.FullName -Value $content -NoNewline
            $totalReplacements += $count
            if (-not $filesModified.ContainsKey($file.FullName)) {
                $filesModified[$file.FullName] = 0
            }
            $filesModified[$file.FullName] += $count
            Write-Host "  [$count] '$old' -> '$new' in $($file.Name)"
        }
    }
}

Write-Host ""
Write-Host "========== SUMMARY =========="
Write-Host "Total replacements: $totalReplacements"
Write-Host "Files modified: $($filesModified.Count)"
foreach ($f in $filesModified.GetEnumerator() | Sort-Object Value -Descending) {
    Write-Host "  $($f.Value) changes: $(Split-Path $f.Key -Leaf)"
}
Write-Host "=============================="
Write-Host "Done! Run 'flutter analyze' to verify."
