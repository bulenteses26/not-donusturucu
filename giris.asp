<%@ Language="VBScript" %>
<!--#include file="guvenlik.asp"-->
<%
Response.CodePage = 65001
Response.Charset = "utf-8"

' Veritabanı bağlantısı
Dim conn, rs, sql
Set conn = Server.CreateObject("ADODB.Connection")
conn.Open "Provider=Microsoft.ACE.OLEDB.12.0;Data Source=" & Server.MapPath("veriler.accdb")

' --- Dropdownlar için veriler ---
Function GetDropdownHTML(sqlQuery, onclickFunc, fieldName)
    Dim rsLocal, result
    Set rsLocal = conn.Execute(sqlQuery)
    result = ""
    Do Until rsLocal.EOF
        result = result & "<li><a class='dropdown-item' style='font-size:10px' href='#' onclick=""" & onclickFunc & "(this)"">" & rsLocal(fieldName) & "</a></li>"
        rsLocal.MoveNext
    Loop
    rsLocal.Close
    Set rsLocal = Nothing
    GetDropdownHTML = result
End Function

Dim unvanlar, birimler, bolumlertb, abdtb
unvanlar = GetDropdownHTML("SELECT DISTINCT unvan_adi FROM unvanlar ORDER BY unvan_adi", "setUnvan", "unvan_adi")
birimler = GetDropdownHTML("SELECT DISTINCT birim_adi FROM birimler ORDER BY birim_adi", "setBirim", "birim_adi")
bolumlertb = GetDropdownHTML("SELECT DISTINCT bolum_adi FROM bolumlertb ORDER BY bolum_adi", "setBolum", "bolum_adi")
abdtb = GetDropdownHTML("SELECT DISTINCT abd_adi FROM abdtb ORDER BY abd_adi", "setABD", "abd_adi")

' SQL Injection'a karşı güvenlik fonksiyonu
Function SqlSafe(value, isNumber)
    If IsNull(value) Then value = ""
    If Trim(value) = "" Then
        SqlSafe = "NULL"
    Else
        If isNumber Then
            SqlSafe = value
        Else
            SqlSafe = "'" & Replace(value, "'", "''") & "'"
        End If
    End If
End Function

' --- GÜNCELLEME ---
If Request.Form("islem") = "guncelle" Then
    Dim setStr : setStr = ""
    Dim alanlar
    alanlar = Array("unvan", "birim", "bolum", "abd", "Talep_miktari", "Talep_tarihi", "Talep_sayisi", "birim_kurul_karari_ts", "bolum_kurul_karari_tarihi", "abd_gorus_tarihi", "Vize_sayisi", "Yoksis_kayit_numarasi", "Vize_tarihi", "Yok_giden_yazi_tarihi", "Yok_giden_yazi_sayisi")

    For Each field In alanlar
        If Request.Form(field) <> "" Then
            If field = "Talep_miktari" Or field = "Talep_sayisi" Or field = "Vize_sayisi" Or field = "Yoksis_kayit_numarasi" Or field = "Yok_giden_yazi_sayisi" Then
                setStr = setStr & field & "=" & SqlSafe(Request.Form(field), True) & ","
            Else
                setStr = setStr & field & "=" & SqlSafe(Request.Form(field), False) & ","
            End If
        End If
    Next

    If Right(setStr, 1) = "," Then setStr = Left(setStr, Len(setStr) - 1)
    sql = "UPDATE kadrolar SET " & setStr & " WHERE id=" & SqlSafe(Request.Form("id"), True)
    conn.Execute sql
    conn.Close
    Set conn = Nothing
    Response.Redirect "giris.asp"
End If

' --- BOŞ KAYIT EKLEME ---
If Request.QueryString("boskopya") <> "" Then
    sql = "INSERT INTO kadrolar (unvan, birim, bolum, abd, Talep_miktari, Talep_tarihi, Talep_sayisi, birim_kurul_karari_ts, bolum_kurul_karari_tarihi, abd_gorus_tarihi, Vize_sayisi, Vize_tarihi, Yoksis_kayit_numarasi, Yok_giden_yazi_sayisi, Yok_giden_yazi_tarihi) " & _
          "VALUES (NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL)"
    conn.Execute sql
    conn.Close
    Set conn = Nothing
    Response.Redirect "giris.asp"
End If

' --- SİLME ---
If Request.QueryString("sil") <> "" Then
    sql = "DELETE FROM kadrolar WHERE id=" & SqlSafe(Request.QueryString("sil"), True)
    conn.Execute sql
    conn.Close
    Set conn = Nothing
    Response.Redirect "giris.asp"
End If

' --- KOPYALAMA ---
If Request.QueryString("kopyala") <> "" Then
    Dim rsKopya
    Set rsKopya = conn.Execute("SELECT * FROM kadrolar WHERE id=" & SqlSafe(Request.QueryString("kopyala"), True))

    If Not rsKopya.EOF Then
        sql = "INSERT INTO kadrolar (unvan, birim, bolum, abd, Talep_miktari, Talep_tarihi, Talep_sayisi, birim_kurul_karari_ts, bolum_kurul_karari_tarihi, abd_gorus_tarihi, Vize_sayisi, Vize_tarihi, Yoksis_kayit_numarasi, Yok_giden_yazi_sayisi, Yok_giden_yazi_tarihi) VALUES (" & _
            SqlSafe(rsKopya("unvan"), False) & "," & _
            SqlSafe(rsKopya("birim"), False) & "," & _
            SqlSafe(rsKopya("bolum"), False) & "," & _
            SqlSafe(rsKopya("abd"), False) & "," & _
            SqlSafe(rsKopya("Talep_miktari"), True) & "," & _
            SqlSafe(rsKopya("Talep_tarihi"), False) & "," & _
            SqlSafe(rsKopya("Talep_sayisi"), True) & "," & _
            SqlSafe(rsKopya("birim_kurul_karari_ts"), False) & "," & _
            SqlSafe(rsKopya("bolum_kurul_karari_tarihi"), False) & "," & _
            SqlSafe(rsKopya("abd_gorus_tarihi"), False) & "," & _
            SqlSafe(rsKopya("Vize_sayisi"), True) & "," & _
            SqlSafe(rsKopya("Vize_tarihi"), False) & "," & _
            SqlSafe(rsKopya("Yoksis_kayit_numarasi"), True) & "," & _
            SqlSafe(rsKopya("Yok_giden_yazi_sayisi"), True) & "," & _
            SqlSafe(rsKopya("Yok_giden_yazi_tarihi"), False) & ")"
        conn.Execute sql
    End If
    rsKopya.Close
    Set rsKopya = Nothing
    conn.Close
    Set conn = Nothing
    Response.Redirect "giris.asp"
End If

' --- KAYIT LİSTELEME SON 15 KAYIT ---
sql = "SELECT TOP 15 * FROM kadrolar ORDER BY id DESC"
Set rs = conn.Execute(sql)
%>



<form method="get" action="giris.asp">
   <a href="/anasayfa.asp" class="btn btn-primary nav-button">
  <i class="fas fa-home"></i> Ana Sayfa</a>

 
</form>

<!DOCTYPE html>
<html lang="tr">
<head>
    <style>
    table {
    border-collapse: collapse;
    width: 120%;
    /* table-layout: fixed; ← bunu geçici olarak kaldırın */
}
    th, td {
           border: 1px solid #ccc;
            padding: 10px;
            position: relative;
            text-align: center;
    }
    .resizer {
            position: absolute;
            right: 0;
            top: 0;
            width: 5px;
            cursor: col-resize;
            user-select: none;
            height: 100%;
    }
     
        .table-responsive {
            overflow-x: auto;
             }
        table {
    min-width: 1550px;
    margin-left: -10%;
   
}

</style>

    <meta charset="UTF-8">
    <title>Kadro Girişi</title>
    <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.2/dist/css/bootstrap.min.css" rel="stylesheet">


<script src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/js/bootstrap.bundle.min.js"></script>
<link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/bootstrap-icons@1.10.5/font/bootstrap-icons.css">
<script src="https://code.jquery.com/jquery-3.7.1.min.js"></script>

</head>
<body class="container mt-4">


 

    <!-- Kayıt Listesi -->
    <table id="kadroTablo" class="table table-bordered table-hover align-middle mt-4">
        <thead class="table-light">
         <tr>  
                <th>id</th>
                <th>Unvan</th>
		        <th>Birim</th>
		        <th>Bölüm</th>
                <th>ABD</th>
                <th>Talep Miktarı</th>
                <th>Talep Tarihi</th>
                <th>Talep Sayısı</th>
                <th>Birim Kurul Kararı TS</th>
                <th>Bölüm Kurul Kararı Tarihi</th>
                <th>ABD Görüş Tarihi</th>
  		<th>durumu</th>

                <th>İşlemler</th>



            </tr>

        </thead>
        <tbody>
            <% Do While Not rs.EOF %>
            <form method="post" action="giris.asp">
                <input type="hidden" name="islem" value="guncelle">
                <input type="hidden" name="id" value="<%=rs("id")%>">
                    <td><%=rs("id")%></td>
 			<td>
			<div class="input-group">
                        <input type="text" name="unvan" class="form-control" value="<%=rs("unvan")%>" placeholder="Unvan seçin">
                        <button class="btn btn-outline-secondary dropdown-toggle" type="button" data-bs-toggle="dropdown">Seç</button>
                        <ul class="dropdown-menu">
                            <%=unvanlar%>
                                
                        </td>
                    </div>
             
                <td>
                      <!-- Birim Seçiniz -->
			<div class="input-group">
                           <input type="text" name="birim" class="form-control" value="<%=rs("birim")%>" placeholder="birim seçin">
                        <button class="btn btn-outline-secondary dropdown-toggle" type="button" data-bs-toggle="dropdown">Seç</button>
                        <ul class="dropdown-menu">                                  
                            <%=birimler%>
                             

</td>
 

                       <td>
			<div class="input-group">
                        <input type="text" name="bolum" class="form-control" value="<%=rs("bolum")%>" placeholder="bolum seçin">
                        <button class="btn btn-outline-secondary dropdown-toggle" type="button" data-bs-toggle="dropdown">Seç</button>
			<ul class="dropdown-menu" data-type="bolum">
                            <%=bolumlertb%>
                  
</td>

                  
  <td>
  <div class="input-group">
    <input type="text" name="abd" class="form-control" value="<%=rs("abd")%>" placeholder="ABD seçin">
    <button class="btn btn-outline-secondary dropdown-toggle" type="button" data-bs-toggle="dropdown">Seç</button>
    <ul class="dropdown-menu" data-type="abd">
	<%=abdtb%>
		</td>

  </div>
</td>

                          
              
            <!------------------------------------tabloda görüntülenecek alanlartexbokslar listbokslar yukarda----------------------->
                  
<td><input type="number" name="Talep_miktari" value="<%=rs("Talep_miktari")%>" class="form-control"></td>
                    <td><input type="text" name="Talep_tarihi" value="<%=rs("Talep_tarihi")%>" class="form-control"></td>
                    <td><input type="number" name="Talep_sayisi" value="<%=rs("Talep_sayisi")%>" class="form-control"></td>
                    <td><input type="text" name="birim_kurul_karari_ts" value="<%=rs("birim_kurul_karari_ts")%>" class="form-control"></td>
                    <td><input type="text" name="bolum_kurul_karari_tarihi" value="<%=rs("bolum_kurul_karari_tarihi")%>" class="form-control"></td>
                    <td><input type="text" name="abd_gorus_tarihi" value="<%=rs("abd_gorus_tarihi")%>" class="form-control"></td>
		
          <!------------------------------------durumunu renklendirme----------------------->            
         <%
    Dim durumRenk
    Select Case rs("durumu")
	Case "BIRIMDEN_TALEP_GELDI"
            durumRenk = "background-color: lightblue; color: black;"
        Case "YOKTE"
            durumRenk = "background-color: turquoise; color: white;"
        Case "YENI_TALEP"
            durumRenk = "background-color: red; color: white;"
        Case "UYK_GIRECEK"
            durumRenk = "background-color: yellow; color: black;"
        Case "UYK_GONDERILDI"
            durumRenk = "background-color: grey; color: white;"
        Case "ILANDA"
            durumRenk = "background-color: pink; color: black;"
        Case "YOKTEN_RED"
            durumRenk = "background-color: orange; color: black;"
        Case "YOKTEN_ONAYLANDI"
            durumRenk = "background-color: green; color: white;"
        Case Else
            durumRenk = ""
    End Select
%>
<td style="<%= durumRenk %>"><%= rs("durumu") %></td>

                    <td>

<!----------------------------------satır sonu butonlar--------------------------------->
                   <div class="d-flex justify-content-start">

</a>
<a href="giris.asp?boskopya=1" class="btn btn-info btn-sm me-1" title="Yeni Kayıt">
  <i class="bi bi-plus-circle-fill"></i>
</a>
  <button type="submit" class="btn btn-primary btn-sm mb-1 me-2" data-bs-toggle="tooltip" data-bs-placement="top" title="Bu kaydı güncelle">
    <i class="bi bi-pencil-square"></i>
  </button>

  <a href="giris.asp?sil=<%=rs("id")%>" 
     class="btn btn-danger btn-sm mb-1 me-2" 
     onclick="return confirm('Silmek istediğinize emin misiniz?');" 
     data-bs-toggle="tooltip" data-bs-placement="top" title="Kaydı sil"> 
    <i class="bi bi-trash"></i>
  </a>

  <a href="giris.asp?kopyala=<%=rs("id")%>" 
     class="btn btn-warning btn-sm me-2" 
     data-bs-toggle="tooltip" data-bs-placement="top" title="Satırdan bir kopya üret">
    <i class="bi bi-files"></i>
</a>
<a href="guncelle.asp?id=<%= rs("id") %>" target="_blank" class="btn btn-sm btn-primary">Detay</a>

</div>


                    </td>
                </tr>
            </form>
            <% 
            rs.MoveNext
            Loop 
            %>
        </tbody>
    </table>
<style>
.popover-arrow-custom {
    position: absolute;
    top: 50%;
    left: -10px;
    width: 0;
    height: 0;
    border-top: 10px solid transparent;
    border-bottom: 10px solid transparent;
    border-right: 10px solid #fff;
}
</style>
<style>
    /* Tüm tablo hücreleri ve içindeki tüm öğeler için geçerli olacak */
    table th, table td,
    table th *, table td * {
        font-size: 10px !important;
        font-family: Arial, sans-serif !important;
    }
</style>


<script>
function setUnvan(item) {
    const selectedValue = item.innerText;
    const input = item.closest('td').querySelector('input[name="unvan"]');
    input.value = selectedValue;
}

function setBirim(el) {
    var birim = el.innerText;
    el.closest(".input-group").querySelector("input").value = birim;

    // Bölüm listesi güncelleniyor
    $.get("bolumgetir.asp?birim=" + encodeURIComponent(birim), function(data) {
        $("ul[data-type='bolum']").html(data);
    });

    // ABD listesi temizleniyor
    $("ul[data-type='abd']").html("");
}

function setBolum(el) {
    var bolum = el.innerText;
    el.closest(".input-group").querySelector("input").value = bolum;

    // Veriyi GET ile abdgetir.asp dosyasına gönder
    $.get("abdgetir.asp?bolum=" + encodeURIComponent(bolum), function(data) {
        $("ul[data-type='abd']").html(data);
    });
}

function setABD(el) {
    el.closest(".input-group").querySelector("input").value = el.innerText;

}     
</script>
    <script>
    window.addEventListener('load', () => {
        const table = document.querySelector("table");
        const cols = table.querySelectorAll("th");

        cols.forEach(th => {
            const resizer = document.createElement("div");
            resizer.classList.add("resizer");
            th.appendChild(resizer);

            let x = 0, w = 0;

            resizer.addEventListener("mousedown", function (e) {
                x = e.clientX;
                w = th.offsetWidth;

                document.addEventListener("mousemove", resize);
                document.addEventListener("mouseup", stopResize);
            });

            function resize(e) {
                const dx = e.clientX - x;
                th.style.width = `${w + dx}px`;
            }

            function stopResize() {
                document.removeEventListener("mousemove", resize);
                document.removeEventListener("mouseup", stopResize);
            }
        });
    });
</script>

  
  </body>
  
      </form>
    </div>
  </div>
  
  </html>
  