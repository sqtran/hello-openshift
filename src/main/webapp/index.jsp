<%@ page import="java.sql.*, javax.sql.*, java.io.*, javax.naming.*, java.util.*" %>
<html>
<head>
<title>Hello World S2I</title>
</head>

<body>
	<h1>Hello World!</h1>
 
    MariaDB Results
	<p>
	<table>
		<tr>
			<th>p_id</th>
			<th>first_name</th>
			<th>last_name</th>
			<th>description</th>
			<th>created_at</th>
		</tr>
	<%    

		Connection conn = null;
		Statement st = null;
		ResultSet rs = null;

		try {
			InitialContext ctx = new InitialContext();
	
			DataSource ds = (DataSource)ctx.lookup("java:/example");
			conn = ds.getConnection();
			st = conn.createStatement();
			rs = st.executeQuery("select * from people");
		
			while(rs != null && rs.next()) {
	%>
		<tr>
			<td><%= rs.getInt("p_id") %></td>
			<td><%= rs.getString("first_name") %></td>
			<td><%= rs.getString("last_name") %></td>
			<td><%= rs.getString("description") %></td>
			<td><%= rs.getTimestamp("created_at") %></td>
		</tr>
	<% 
			} // end while 
		} catch (Exception e) {
			e.printStackTrace();
		} finally {
			if(rs != null) rs.close();
			if(st != null) st.close();
			if(conn != null) conn.close();
		}
	%>
	</table>
</body>
