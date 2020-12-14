<%@ page import="java.sql.*, javax.sql.*, java.io.*, javax.naming.*, java.util.*" %>
<html>
<head>
<title>Hello World!</title>
</head>
<body>
	<h1>Hello World!</h1>
	<p>
		It is now
		<%= new java.util.Date() %></p>
	<p>
		You are coming from 
		<%= request.getRemoteAddr()  %></p>
	<p>
		You are accessing  
		<%= request.getLocalName()  %> (<%= request.getLocalAddr() %>) (<%= InetAddress.getLocalHost().getHostName() %>)</p>

	<h2>Environment Variables:</h2>

	<table>
	<tr style="text-align:left;">
	<th>Key</th><th>Value</th>
	</tr>
	<%
		Map<String, String> env = System.getenv();
		for (String envName : env.keySet()) {
	%>
		<tr><td><%= envName %></td><td><%= env.get(envName) %></td></tr>
	<%
		}
	%>
	</table>

	<h2> MariaDB Datasource </h2>
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
